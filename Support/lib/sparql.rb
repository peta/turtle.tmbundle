#!/usr/bin/env ruby

require "net/http"
require "uri"

require ENV['TM_SUPPORT_PATH'] + '/lib/osx/plist'
require ENV['TM_SUPPORT_PATH'] + '/lib/ui'
require ENV['TM_SUPPORT_PATH'] + '/lib/current_word'

module Turtle
  module SPARQL
    
    # Tells what part of the SPARQL language the given query string makes use of (either :update or :query)
    # @return [Symbol]
    def self.which_type?(qry_text)
      (qry_text =~ /(INSERT|DELETE|LOAD|CLEAR|CREATE|DROP|WITH)/) ? :update : :query
    end
    
    # Helper function for raising errors    
    def self.raise_error(level, title, msg, exit = true)
      TextMate::UI::alert(level, title, msg)
      TextMate::exit_discard if exit
    end
    
    # Helper function for finding a suitable endpoint
    # @return [String, NilClass]
    def self.get_endpoint(type, section)
      new_ep = section.first_endpoint(type)
      new_ep = section.parent.first_endpoint(section.from_line, :bottom_up, type) if new_ep.nil?      
      # nothing found, check environment and finally ask user
      if new_ep.nil?
        # Check if an endpoint is set by an ENV variable
        if ENV['TM_SPARQL_'+type.to_s.upcase]
          new_ep = ENV['TM_SPARQL_'+type.to_s.upcase]
        # Ask user
        else
          new_ep = TextMate::UI::request_string(
            :title  => 'Choose SPARQL Endpoint',
            :prompt => 'Please enter URL of SPARQL '+type.to_s.upcase+' Service')    
        end
        new_ep = (new_ep.to_s.strip.empty?) ? nil : new_ep
      else
        new_ep = new_ep.value
      end
      new_ep
    end
    
    # Represents a SPARQL document and offers an API for accessing its sections and endpoint markers    
    class Document
      
      SECTION_MARKER = /^#---$/
      SECTION_PROP = /^#([a-z0-9.:_\-]+)=\s+(.+)$/
      
      def initialize(content)
        @sections = []
        @state = :idle
        @current = nil
        parse(content)
      end
      
      # Iterates over all sections contained by current document      
      def each(&block)
        if block_given?
          @sections.each(&block)
        else
          @sections.to_enum
        end
      end
      
      # Gets +Section+ object that spans over then given line number
      # @return [Section,NilClass]
      def section_at_line(line_no)
        @sections.each do |s|
          return s if s.has_line_number?(line_no)
        end
      end
      alias_method :[], :section_at_line
      
      # Tells if current document contains section with given `name`
      # @return [Boolean]
      def has_section?(name)        
        return false if name.nil?
        @sections.each do |s|
          return true if s.name == name
        end
      end
      
      # Returns document section with given name
      # @return [Section,NilClass]
      def find_section(name)
        return if name.nil?
        @sections.each do |s|
          return s if s.name == name
        end        
      end
      
      def [](line_no)
        return if line_no.nil?
        line_no = line_no.to_i
        @doc_lines[line_no]
      end
      
      # Returns the first endpoint found by applying the given parameters or `nil`
      # when no suitable endpoint was found.
      #
      # @paran [NilClass, Fixnum] line_no
      # @param [Symbol] strategy
      # @param [Symbol, NilClass] type
      # @return [NilClas, String]
      def first_endpoint(line_no = nil, strategy = :top_bottom, type = nil)
        return unless @sections.any?
        
        # Determine index of section where we start searching at
        if not line_no.nil?          
          from_idx = @sections.index do |s|
            line_no.between? s.from_line, s.to_line
          end; return if from_idx.nil?
        else
          from_idx = (strategy === :top_bottom) ? 0 : @sections.count
        end
        
        # Build range
        case strategy
          when :top_bottom
            range = from_idx.upto(@sections.count)
          when :bottom_up
            range = from_idx.downto(0)
          else
            return      
        end

        # And scan it
        range.each do |idx|
          ep_marker = @sections.at(idx).first_endpoint(type)
          return ep_marker.value if (type.nil? or not ep_marker.nil?)
        end
      end
      
      def inspect()
        str = "Document contains #{@sections.count} sections(s)\n\n"
        @sections.each {|s| str += s.inspect + "\n\n--------------------\n\n" }
        return str
      end
      
      private
      
      # Parses the given document string
      # @param [String] doc_str
      def parse(doc_str)
        return unless @state === :idle
        @state = :in_doc
        # Begin document parsing
        doc_lines = doc_str.lines.map(&:chomp!)
        doc_lines.each_with_index do |line,no|
          case @state
            when :in_doc
              begin_section(no)
              @state = :in_sect
              redo
            when :in_sect
              # 1. scan for magic comments
              case line
                when SECTION_PROP
                  # It's a section property
                  name = Regexp.last_match[1]
                  value = Regexp.last_match[2]
                  found_property name, value
                when SECTION_MARKER
                  # Section ends here
                  end_section([0, no-1].max) # (more precisely: in the previous before)
                  @state = :in_doc                  
                else
                  # Just add line to current section
                  found_line line
              end                            
            else
              break
          end
        end; if @state == :in_sect
          # Close remaining section
          end_section(doc_lines.count - 1)  
          @state = :in_doc
        end
        # Shutdown
        @state = :idle
      end          
      
      # Start new document section
      # @param [Fixnum] line_no
      def begin_section(line_no)
        return unless @state === :in_doc
        @current = Section.new(self, line_no)
      end
      
      # Handle the line of code found by the parser
      # @param [String] line
      def found_line(line)
        return unless @state === :in_sect
        @current << line        
      end
      
      # Handle the sectin property found by the parser
      # @param [String] name
      # @param [String] value
      def found_property(name, value)
        return unless @state === :in_sect
        @current.properties[name] = value
      end
       
      # Finalize current document section and return it     
      # @return [Turtle::SPARQL::Section]
      def end_section(line_no)
        return unless @state === :in_sect        
        sect = @current        
        sect.freeze(line_no)
        @sections << sect unless sect.empty?
        @current = nil        
        return sect
      end
                  
    end # Document
      
    
    # Represents a document section and offers an API for accessing
    # its metadata, queries, markers and (specialized marker) endpoints 
    class Section
      
      MARKER_PATTERN = /^#[A-Z]+[^=]?/
      
      attr_reader :lines, :properties, :from_line, :to_line, :parent
      
      def initialize(parent_doc, from_line, lines = [])
        @lines = lines.to_a
        @parent = parent_doc
        @properties = {}         
        @from_line = from_line.to_i
        @to_line = nil
        @queries = [[]]
      end
      
      # Tells if current section spans over given line number
      # @return [Boolean]
      def has_line_number?(num)
        num.between? @from_line, @to_line
      end
      
      # Finishes the current section and does postprocessing
      def freeze(to_line)
        @to_line = to_line.to_i
        @lines.each do |line|                     
          if line =~ MARKER_PATTERN and (marker = Marker.from(line))            
            if @queries[-1].is_a? Array
              # Flatten last query and clean up
              last_qry = @queries[-1].join("\n")
              if last_qry.strip.empty?
                @queries.slice!(-1)
              else
                @queries[-1] = last_qry
              end
            end
            # Add marker and new array for ordinary lines of text
            @queries << marker
            @queries << []
            next
          end
          # Add line to current query
          @queries[-1] << line unless line.strip.empty?
        end
        unless @queries[-1].is_a? Marker
          # Flatten last query and clean up
          last_qry = @queries[-1].join("\n")
          if last_qry.strip.empty?
            @queries.slice!(-1)
          else
            @queries[-1] = last_qry
          end          
        end
        super()
      end
      
      # Name of current section
      # return [String,NilClass]
      def name
        @properties['name']
      end
      
      # Tells whether current section is empty
      # @return [Boolean]
      def empty?
        @lines.empty? and @properties.empty?
      end
      
      def each(&block)
        @queries.each(&block)
      end
      
      # Iterates over all +Markers+ contained in current section
      def each_marker(&block)
        markers = @queries.select {|qry| qry.is_a? Marker }        
        (block_given?) ? markers.each(&block) : markers.to_enum
      end
      
      # Iterates over all endpoint +Markers+ contained in current section
      def first_endpoint(type = nil)        
        @queries.each do |q|
          return q if q.is_a?(Marker) and (type.nil? or q.type_of?(type))
        end
        nil
      end
      
      # Iterates over all queries contained in current +Section+ object
      def each_query(&block)       
        return enum_for(:each_query) unless block_given?
        @queries.each do |qry|
          if qry.is_a? Marker            
            if qry.type_of? :include
              # Include other section
              include_name = qry.value
              # Prevent recursion
              next unless include_name != self.name
              # Tell user when he tries to include a non-existing section 
              unless @parent.has_section? include_name
                SPARQL.raise_error :critical, 'Index error', "No section with name '#{include_name}' found. Inclusion inside section '#{self.name}' failed."
              end
              # Evaluate inclusion
              @parent.find_section(include_name).each_query(&block)
            end            
          else
            # Return query code
            block.call(qry)
          end
        end
      end
      
      def <<(line)
        @lines << line
      end
      
      def [](idx)
        @lines[idx]
      end
      
      def to_s
        @lines.join("\n")
      end
      
      def inspect()
        dump = ["BEGIN SECTION DUMP (#{from_line}–#{to_line})"]
        dump << "========\nPROPERTIES\n========="
        if @properties.any?
          @properties.each do |k,v|
            dump << "'#{k}': '#{v}'"
          end
        else
          dump << 'NO PROPS AVAILABLE'
        end            
        dump << "========\nMARKERS\n========="
        dump += self.each_marker.map {|m| m.inspect }
        dump << "========\nQUERIES (#{@queries.count})\n========="
        dump += @queries.map {|q| q.inspect }
        dump << "========\nCONTENT\n========="
        dump += @lines          
        dump << "\n\nEND SECTION DUMP\n"
        return dump.join("\n")
      end        
    end # Section
    
    
    # A +Marker+ is a processing instruction embedded as magic comment. The +Marker+
    # class simply encapsulates the marker name (aka its `type`) and the according
    # value.
    class Marker
      @@known_types = [:query, :update, :include]

      # Kind of factory method that tries to create a +Marker+ object from the given
      # line of query code. Returns +NilClass+  when creation fails.
      # @return [Turtle::SPARQL::Marker, NilClass]
      def self.from(line)
        types = @@known_types.map {|t| t.to_s.upcase }.join('|')
        if line =~ /^#(#{types})\s+<([^>]+)>\s*$/
          return self.new(Regexp.last_match[1].downcase.to_sym, Regexp.last_match[2])
        end
      end
      
      attr_reader :type, :value
      
      def initialize(type, value)
        @type = type
        @value = value
      end
      
      # Tells whether the current +Marker+ object is of the given `type`
      # @return [Boolean]
      def type_of?(sym)
        @type === sym
      end        
    end # Marker
    
  end # SPARQL
end # Turtle
