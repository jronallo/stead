require 'helper'

class TestSteadEadSeries < Test::Unit::TestCase
  include SteadTestHelpers

  def setup
    @xsd = Nokogiri::XML::Schema(File.read(Stead.ead_schema))
    
    @example = Nokogiri::XML(File.read(File.join(File.dirname(__FILE__),
          'container_lists', 'mc00000-ead-series.xml' )))
    @ead_generator = Stead::EadGenerator.from_csv(File.read(File.join(File.dirname(__FILE__),
          'container_lists', 'mc00000_container_list.csv' )))
    @generated_ead = @ead_generator.to_ead
    
    @did_xpath = '//xmlns:c02/xmlns:did'
  end

  def test_ead_c01_counts
    assert_equal 3, @generated_ead.xpath('//xmlns:c01').length
  end

  def test_ead_c02_counts
    assert_equal 5, @generated_ead.xpath('//xmlns:c02').length
  end
  
  def test_ead_c03_counts
    assert_equal 2, @generated_ead.xpath('//xmlns:c03').length
  end

  def test_validity
    assert @xsd.valid?(@generated_ead)
  end

  def test_created_ead_matches_example_content
    (0..4).each do |number|
      #puts number
      did = @generated_ead.xpath(@did_xpath)[number]
      example_did = @example.xpath(@did_xpath)[number]
      #assert_equal 'file', did.parent['level']
      assert_main_elements_equal(did, example_did)
    end
  end

  def test_has_controlaccess
    assert_equal 1, @generated_ead.xpath('//xmlns:c02/xmlns:controlaccess').length
  end

  def test_has_controlaccess_geogname
    geonames = @generated_ead.xpath('//xmlns:c02/xmlns:controlaccess/xmlns:geogname')
    assert_equal 1, geonames.length
    assert_equal 'Raleigh (N.C.)', geonames.first.content
    assert_equal 'lcnaf', geonames.first['source']
  end

  def test_has_controlaccess_corpname
    corpnames = @generated_ead.xpath('//xmlns:c02/xmlns:controlaccess/xmlns:corpname')
    assert_equal 1, corpnames.length
    assert_equal 'corpname', corpnames.first.content
    assert_equal 'corpname_source', corpnames.first['source']
  end


end

