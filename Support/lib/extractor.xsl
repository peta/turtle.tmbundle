<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
	xmlns:owl="http://www.w3.org/2002/07/owl#"
	exclude-result-prefixes="rdf rdfs owl"
	version="1.0">
	
	<xsl:output method="xml" indent="yes" cdata-section-elements="label description" />
	
	<xsl:param name="base-uri"/>	
	
	<xsl:variable name="chars_upper" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZÄÖÜ'"/>
	<xsl:variable name="chars_lower" select="'abcdefghijklmnopqrstuvwxyzäöü'"/>
	
	<xsl:template match="/rdf:RDF">
		<model>
			<xsl:attribute name="base-uri-passed">
				<xsl:value-of select="$base-uri"/>
			</xsl:attribute>
			<xsl:apply-templates select="*[@rdf:about != $base-uri and starts-with(@rdf:about, $base-uri) and not(self::rdf:Description or self::owl:Class or self::owl:DatatypeProperty or self::owl:ObjectProperty or self::owl:AnnotationProperty or self::rdfs:Class or self::rdf:Property or self::rdfs:Datatype or self::rdf:List)]"/>
			<xsl:apply-templates select="owl:Class|owl:DatatypeProperty|owl:ObjectProperty|owl:AnnotationProperty|rdfs:Class|rdf:Property|rdfs:Datatype|rdf:List"/>
			<xsl:apply-templates select="rdf:Description[@rdf:about != $base-uri]"/>
		</model>
	</xsl:template>

	<xsl:template match="*[not(self::rdf:Description or self::owl:Class or self::owl:DatatypeProperty or self::owl:ObjectProperty or self::owl:AnnotationProperty or self::rdfs:Class or self::rdf:Property or self::rdfs:Datatype or self::rdf:List)]">
		<resource>
			<xsl:attribute name="prefix">
				<xsl:value-of select="substring-before(name(), ':')"/>
			</xsl:attribute>
			<xsl:attribute name="type">instance</xsl:attribute>
			<xsl:call-template name="id-attrib"/>
			<xsl:call-template name="docu"/>
		</resource>
	</xsl:template>

	<xsl:template match="rdf:Description[string-length(rdf:type/@rdf:resource)>0]">
	<xsl:if test="starts-with(@rdf:about, $base-uri) or (starts-with(@rdf:about, '#') and string-length(substring-after(@rdf:about, '#')) > 0)">
		<xsl:variable name="resource_type" select="rdf:type/@rdf:resource"/>
		<resource>			
			<xsl:attribute name="prefix">
				<xsl:for-each select="namespace::*">
					<xsl:if test="starts-with($resource_type, .)">
						<xsl:value-of select="local-name(.)"/>
					</xsl:if>
				</xsl:for-each>
			</xsl:attribute>
			<xsl:attribute name="type">
				<xsl:variable name="tmp_type">
					<xsl:choose>
                        <xsl:when test="starts-with($resource_type, $base-uri)">instance</xsl:when>
                        <xsl:when test="string-length(substring-after($resource_type, '#')) > 0">
                                <xsl:value-of select="substring-after($resource_type, '#')"/>
                        </xsl:when>
                        <xsl:otherwise>instance</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<xsl:value-of select="translate($tmp_type, $chars_upper, $chars_lower)"/>				
			</xsl:attribute>
			<xsl:call-template name="id-attrib"/>
			<xsl:call-template name="docu"/>
		</resource>
	</xsl:if>
	</xsl:template>
	
	<xsl:template match="owl:Class[@rdf:about]|owl:DatatypeProperty[@rdf:about]|owl:ObjectProperty[@rdf:about]|owl:AnnotationProperty[@rdf:about]|rdfs:Class[@rdf:about]|rdf:Property[@rdf:about]|rdfs:Datatype[@rdf:about]|rdf:List[@rdf:about]">	
	<xsl:if test="starts-with(@rdf:about, $base-uri) or (starts-with(@rdf:about, '#') and string-length(substring-after(@rdf:about, '#')) > 0)">
		<resource>
			<xsl:attribute name="prefix">
				<xsl:value-of select="substring-before(name(), ':')"/>
			</xsl:attribute>
			<xsl:attribute name="type">
				<xsl:value-of select="translate(local-name(.), $chars_upper, $chars_lower)"/>
			</xsl:attribute>
			<xsl:call-template name="id-attrib"/>
			<xsl:call-template name="docu"/>
		</resource>		
	</xsl:if>
	</xsl:template>
	
	<xsl:template name="id-attrib">
		<xsl:attribute name="id">			
			<xsl:choose>
				<xsl:when test="starts-with(@rdf:about, $base-uri)">
					<!-- fully qualified URIrefs -->
					<xsl:value-of select="substring-after(@rdf:about, $base-uri)"/>
				</xsl:when>
				<xsl:when test="string-length(substring-after(@rdf:about, '#')) > 0">
					<!-- relative URIrefs -->
					<xsl:value-of select="substring-after(@rdf:about, '#')"/>
				</xsl:when>
				<xsl:otherwise>
					<!-- URI -->
					<xsl:value-of select="@rdf:about"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:attribute>
	</xsl:template>
	
	<xsl:template name="docu">
		<label><xsl:value-of select="rdfs:label/text()"/></label>
		<description>
			<xsl:attribute name="definedBy">
				<xsl:value-of select="rdfs:isDefinedBy/text()"/>
			</xsl:attribute>
			<xsl:attribute name="seeAlso">
				<xsl:value-of select="rdfs:seeAlso/text()"/>
			</xsl:attribute>
			<xsl:value-of select="rdfs:comment/text()"/>
		</description>
	</xsl:template>
	
</xsl:stylesheet>