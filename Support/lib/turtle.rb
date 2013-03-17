#!/usr/bin/env ruby

DEBUG = false

SUPPORT_DIR = ENV['TM_BUNDLE_SUPPORT']
CACHE_DIR = "#{ENV['TM_BUNDLE_SUPPORT']}/cache"
CACHE_LIFETIME = 60*60*24
IMG_DIR = "#{ENV['TM_BUNDLE_SUPPORT']}/img"

ICONS = {
  "M"      => "#{IMG_DIR}/item-icons/Macros.png",
  "L"   => "#{IMG_DIR}/item-icons/Languages.png",
  "Doc"   => "#{IMG_DIR}/item-icons/Template Files.png",
  "T"  => "#{IMG_DIR}/item-icons/Templates.png",
  "S"    => "#{IMG_DIR}/item-icons/Snippets.png",
  "P" => "#{IMG_DIR}/item-icons/Preferences.png",
  "D"       => "#{IMG_DIR}/item-icons/Drag Commands.png",
  "C"    => "#{IMG_DIR}/item-icons/Commands.png"
}

require "net/http"
require "uri"
require "yaml"
require "rexml/document"
include REXML

require ENV['TM_SUPPORT_PATH'] + '/lib/osx/plist'
require ENV['TM_SUPPORT_PATH'] + '/lib/ui'
require ENV['TM_SUPPORT_PATH'] + '/lib/current_word'

module Turtle
# BEGIN MODULE

class Prefixes
  PREFIX_FPATH = "#{CACHE_DIR}/prefixes.yml"
  PREFIX_CC_URL = "http://prefix.cc/popular/all.file.txt"
  
  def Prefixes.get_all(force_reload = false) 
    if force_reload or ((not File.exists? PREFIX_FPATH) or (Time.now - File.mtime(PREFIX_FPATH)) > CACHE_LIFETIME)
      # Cache file older than 24h => reload
      File.open(PREFIX_FPATH, "w") do |f|
        YAML::dump(download(), f)
      end
    end
    f = File.open(PREFIX_FPATH, "r")
    prefixes = YAML::load(f)
    f.close
    return prefixes
  end
    
  def Prefixes.lookup(pref)
    prefixes = get_all()
    prefixes.has_key?(pref) ? prefixes[pref] : nil
  end

  def Prefixes.download
    prefixes = {}
    url = URI.parse(PREFIX_CC_URL)
    http = Net::HTTP.new(url.host, url.port)
    resp = http.request(Net::HTTP::Get.new(url.request_uri))  
    if ("200" != resp.code or "text/plain" != resp.content_type)
      return prefixes
    end 
    resp.body.each_line do |line|
      frags = line.split("\t")
      if not frags[0].start_with? '#'
        # Exclude EOL byte
        prefixes[frags[0]] = frags[1][0..-2]
      end
    end  
    prefixes  
  end  
end

class Model    
  # TODO: Introduce additional caching layer for public API?
  
  XSL_FPATH = SUPPORT_DIR+'/lib/extractor.xsl'
  MODEL_FPATH_TPL = CACHE_DIR+'/%s.xml'  
  CMD_TPL = <<-SH
    bash;
    set -o pipefail;
    curl -s -L -A 'Turtle.tmBundle' -H 'Accept: application/rdf+xml, application/owl+xml' '%s' \
      | xsltproc --stringparam 'base-uri' '%s' '%s' - >'%s' 2>/dev/null
  SH
  
  attr_accessor :prefix, :uri
    
  def initialize(prefix, uri = nil, force_reload = false)
    @prefix, @uri, @url = prefix, uri, nil
    if @uri.nil?
      @uri = Prefixes.lookup(@prefix) 
    end
    @loaded = false
    # Load model
    if not @uri.nil?
      @url = (@uri.end_with? '#') ? @uri[0..-2] : @uri      
      fpath = MODEL_FPATH_TPL % prefix
      # Dummy file is used to keep track of vocabs/ontos 
      # for which no machine readable representation exists.
      # That way we don't try to fetch useless data over and over again 
      fpath_dummy = fpath + '.na'
      # Check if cache should be re-/generated
      if force_reload or not (File.file? fpath_dummy and (Time.now - File.mtime(fpath_dummy)) < CACHE_LIFETIME)
        (File.unlink fpath_dummy) rescue 'IGNORE'
        if force_reload or
            ((not File.file? fpath) or 
            (Time.now - File.mtime(fpath)) > CACHE_LIFETIME or
             File.size(fpath).zero?)
           if system "#{CMD_TPL % [@uri, @uri, XSL_FPATH, fpath]}"
             # Cache successfully generated => inform user
             TextMate::UI.tool_tip "<p style=\"padding:3px 4px;background-color:#008800;color:#fff;font-family:'Lucida Grande';\">Resources for prefix <span style=\"font-weight:bold;text-decoration:underline;\">#{@prefix}:</span> sucessfully extracted</h3>", :format => 'html', :transparent => true 
           else
             # No suitable machine readable representation available
             # => create dummy file
             `touch '#{fpath_dummy}'`
             # And inform user
             TextMate::UI.tool_tip <<-HTML, :format => :html, :transparent => true
               <p style="padding:3px 4px;background-color:#cc1111;color:#fff;font-family:'Lucida Grande';">No autocompletion for current prefix available</h3>
             HTML
           end
        end
      end
      if File.file? fpath and File.size(fpath).nonzero?
        @xml = Document.new(File.open(fpath, 'r'))
        @loaded = true
      end
    end
  end
    
  def to_s
    '%s: <%s>' % [@prefix, @uri]
  end
    
  def available?
    return @loaded
  end
  
  def resource(id)
  end
    
  def resources(type = 'all')
    return nil if not available?
    filter = (type == 'all') ? '' : "[@type=#{type}]"
    @xml.each_element("//resource#{filter}/@id")
  end
    
  def explain(id)
    return nil if not available?
    doc = {}
    @xml.each_element("/model/resource[@id='#{id}']/*") do |el|
      doc[el.name] = el.text
      if 'description' == el.name
        el.attributes.each { |k,v| doc[k] = v }
      end
    end
    return doc
  end
   
end
  
# END MODULE
end
