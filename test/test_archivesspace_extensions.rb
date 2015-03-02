require 'helper'

class TestArchivesspaceExtensions < Test::Unit::TestCase
  include SteadTestHelpers

  def setup
    csv_file = File.read(File.join(File.dirname(__FILE__),
          'container_lists', 'mc00000_container_list_no_series.csv' ))
    @ead_generator = Stead::EadGenerator.from_csv(csv_file,
      :idcontainers => true, :unitid => 'MC00000', :extent => '1 box', :unitdate => '1973 bulk')
    @generated_ead = @ead_generator.to_ead
    @archdesc_did = @generated_ead.xpath('//xmlns:archdesc/xmlns:did')
  end

  def test_component_parts_have_attributes
    did = @generated_ead.xpath('//xmlns:c01').first
    containers = did.xpath('xmlns:did/xmlns:container')
    assert containers[0].has_attribute?('id')
    assert containers[1].has_attribute?('parent')
    assert_equal containers[0].attribute('id').value, containers[1].attribute('parent').value

    assert containers[1].has_attribute?('id')
    assert containers[2].has_attribute?('parent')
    assert_equal containers[1].attribute('id').value, containers[2].attribute('parent').value
  end

  def test_adding_archdesc_unitid
    unitid = @archdesc_did.xpath('xmlns:unitid').text
    assert_equal 'MC00000', unitid
  end

  def test_adding_archdesc_extent
    extent = @archdesc_did.xpath('xmlns:physdesc/xmlns:extent').text
    assert_equal '1 box', extent
  end

  def test_adding_archdesc_unitdate
    unitdate = @archdesc_did.xpath('xmlns:unitdate').text
    assert_equal '1973 bulk', unitdate
  end

end

