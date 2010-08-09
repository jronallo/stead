require 'helper'

class TestSteadEadSeries < Test::Unit::TestCase
  include SteadTestHelpers

  def setup
    @xsd = Nokogiri::XML::Schema(File.read(Stead.ead_schema))
    #@template = Nokogiri::XML(File.read(Stead.ead_template))
    @example = Nokogiri::XML(File.read(File.join(File.dirname(__FILE__),
          'container_lists', 'mc00000-ead-series.xml' )))
    @ead_generator = Stead::EadGenerator.from_csv(File.read(File.join(File.dirname(__FILE__),
          'container_lists', 'mc00000_container_list.csv' )))
    @generated_ead = @ead_generator.to_ead
    #puts Stead.pretty_write(@generated_ead)
    @did_xpath = '//xmlns:c02/xmlns:did'
  end

  def test_ead_c01_counts
    assert_equal 3, @generated_ead.xpath('//xmlns:c01').length
  end

  def test_ead_c02_counts
    assert_equal 5, @generated_ead.xpath('//xmlns:c02').length
  end

  def test_validity
    assert @xsd.valid?(@generated_ead)
  end

  def test_created_ead_matches_example_content
    (0..4).each do |number|
      #puts number
      did = @generated_ead.xpath(@did_xpath)[number]
      example_did = @example.xpath(@did_xpath)[number]
      assert_equal 'file', did.parent['level']
      assert_main_elements_equal(did, example_did)
    end
  end


end

