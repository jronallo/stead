require 'helper'

class TestDuplicateSeriesTitle < Test::Unit::TestCase
  
  def setup
    @xsd = Nokogiri::XML::Schema(File.read(Stead.ead_schema))
    
    #@example = Nokogiri::XML(File.read(File.join(File.dirname(__FILE__),
    #      'container_lists', 'snyderman2.xml' )))
    @ead_generator = Stead::EadGenerator.from_csv(File.read(File.join(File.dirname(__FILE__),
          'container_lists', 'snyderman3.csv' )))
    @generated_ead = @ead_generator.to_ead
  end
  
  def test_c01_counts
    assert_equal 2, @generated_ead.xpath('//xmlns:c01').length
  end
  
  def test_c02_counts
    assert_equal 2, @generated_ead.xpath('//xmlns:c02').length
  end
  
  def test_each_c01_has_one_c02
    @generated_ead.xpath('//xmlns:c01').each do |c01|
      assert_equal 1, c01.xpath('xmlns:c02').length
    end
  end
    
  
end