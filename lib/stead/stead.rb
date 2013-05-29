module Stead

  def self.ead_schema
    File.expand_path(File.join(File.dirname(__FILE__), 'templates','ead.xsd'))
  end

  def self.xsd
    Nokogiri::XML::Schema(File.read(Stead.ead_schema))
  end

  def self.ead_template
    File.expand_path(File.join(File.dirname(__FILE__), 'templates','ead.xml'))
  end

  def self.ead_template_xml
    Nokogiri::XML(File.read(self.ead_template))
  end

  def self.pretty_write(xml)
    if xml.is_a? String
      self.write(xml)
    elsif xml.is_a? Nokogiri::XML::Document or xml.is_a? Nokogiri::XML::Node
      self.write(xml.to_xml)
    end
  end

   def self.write(buffer)

      xsl =<<XSL
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="xml" encoding="UTF-8"/>
<xsl:param name="indent-increment" select="' '"/>
<xsl:template name="newline">
<xsl:text disable-output-escaping="yes">
</xsl:text>
</xsl:template>
<xsl:template match="comment() | processing-instruction()">
<xsl:param name="indent" select="''"/>
<xsl:call-template name="newline"/>
<xsl:value-of select="$indent"/>
<xsl:copy />
</xsl:template>
<xsl:template match="text()">
<xsl:param name="indent" select="''"/>
<xsl:call-template name="newline"/>
<xsl:value-of select="$indent"/>
<xsl:value-of select="normalize-space(.)"/>
</xsl:template>
<xsl:template match="text()[normalize-space(.)='']"/>
<xsl:template match="*">
<xsl:param name="indent" select="''"/>
<xsl:call-template name="newline"/>
<xsl:value-of select="$indent"/>
<xsl:choose>
<xsl:when test="count(child::*) > 0">
<xsl:copy>
<xsl:copy-of select="@*"/>
<xsl:apply-templates select="*|text()">
<xsl:with-param name="indent" select="concat ($indent, $indent-increment)"/>
</xsl:apply-templates>
<xsl:call-template name="newline"/>
<xsl:value-of select="$indent"/>
</xsl:copy>
</xsl:when>
<xsl:otherwise>
<xsl:copy-of select="."/>
</xsl:otherwise>
</xsl:choose>
</xsl:template>
</xsl:stylesheet>
XSL

      doc = Nokogiri::XML(buffer)
      xslt = Nokogiri::XSLT(xsl)
      out = xslt.transform(doc)
      out.to_xml
    end

end

