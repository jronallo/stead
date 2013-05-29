require 'helper'

class TestSteadEadNoSeries < Test::Unit::TestCase
  include SteadTestHelpers

  def setup
    @xsd = Nokogiri::XML::Schema(File.read(Stead.ead_schema))
    #@template = Nokogiri::XML(File.read(Stead.ead_template))
    @example = Nokogiri::XML(File.read(File.join(File.dirname(__FILE__),
          'container_lists', 'mc00000-ead.xml' )))
    @ead_generator = Stead::EadGenerator.from_csv(File.read(File.join(File.dirname(__FILE__),
          'container_lists', 'mc00000_container_list_no_series.csv' )))
    @generated_ead = @ead_generator.to_ead
    #puts Stead.pretty_write(@generated_ead)
    @did_xpath = '//xmlns:dsc/xmlns:c01/xmlns:did'
  end

  def test_creation_of_eadxml_counts
    assert_equal 1, @example.xpath('//xmlns:dsc').length
    assert_equal 1, @generated_ead.xpath('//xmlns:dsc').length
    assert_equal 5, @generated_ead.xpath('//xmlns:c01').length
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

  def test_notes
    notes = @generated_ead.xpath(@did_xpath).first.xpath('xmlns:note')
    assert_equal 'note1', notes.first.xpath('xmlns:p').first.content
    assert_equal 'note2', notes[1].xpath('xmlns:p').first.content
  end

  def test_scopecontent
    last_cp = @generated_ead.xpath('//xmlns:c01').last
    scopecontent = last_cp.xpath('./xmlns:scopecontent/xmlns:p').first.content
    assert_equal 'Sessions 32-38', scopecontent
  end

  def test_validity
    assert @xsd.valid?(@generated_ead)
  end

  def test_internal_only
    assert_equal 'internal',
      @generated_ead.xpath(@did_xpath).first.parent['audience']
  end

  def test_accessrestrict
    last_cp = @generated_ead.xpath('//xmlns:c01')[3]
    accessrestrict = last_cp.xpath('./xmlns:accessrestrict').first.content
    assert_equal 'Restricted', accessrestrict
  end

  def test_container_label
    container = @generated_ead.xpath('//xmlns:container').first
    assert_equal 'Mixed materials', container['label']
  end

  def test_three_containers
    first_did = @generated_ead.xpath(@did_xpath).first
    containers = first_did.xpath('xmlns:container')
    assert_equal 3, containers.length
    assert_equal 'box', containers.first['type']
    assert_equal '45', containers.first.content
    assert_equal 'folder', containers[1]['type']
    assert_equal '404', containers[1].content
    assert_equal 'artifactbox', containers[2]['type']
    assert_equal '3', containers[2].content
  end

  def test_missing_container_type
    did = @generated_ead.xpath(@did_xpath)[3]
    containers = did.xpath('xmlns:container')
    assert_equal 2, containers.length
    assert_equal 'box', containers[0]['type']
    assert_equal '58', containers[0].content
    assert_equal 'othertype', containers[1]['type']
    assert_equal '551', containers[1].content
  end

end

