require 'helper'

class TestWheless < Test::Unit::TestCase
  include SteadTestHelpers
  def setup
    #@example = Nokogiri::XML('')
    @ead_generator = Stead::EadGenerator.from_csv(File.read(File.join(File.dirname(__FILE__),
          'container_lists', 'wheless.csv' )))
    @generated_ead = @ead_generator.to_ead
  end
  
  def test_lack_of_empty_c01_at_end
    last_c01 = @generated_ead.xpath('//xmlns:c01').last
    assert !EquivalentXml.equivalent?("<c01 level=\"file\">\n  <did/>\n</c01>", 
      last_c01.to_xml, opts = { :element_order => false, :normalize_whitespace => true })
  end
  
  
  
  # def test_lack_of_empty_note
  #   assert_nil @generated_ead.xpath('//c01/did/note')
  # end
  
    
end