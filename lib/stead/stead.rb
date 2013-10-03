module Stead

  def self.ead_schema
    File.expand_path(File.join(File.dirname(__FILE__), 'templates','ead.xsd'))
  end

  def self.ead_template
    File.expand_path(File.join(File.dirname(__FILE__), 'templates','ead.xml'))
  end

  def self.ead_template_xml
    Nokogiri::XML(File.read(self.ead_template))
  end

  def self.pretty_write(xml)
    Nokogiri::XML(xml.to_xml, &:noblanks).to_xml(indent: 4)
  end

end

