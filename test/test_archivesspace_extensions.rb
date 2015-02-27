require 'helper'

class TestArchivesspaceExtensions < Test::Unit::TestCase
  include SteadTestHelpers

  def setup
    csv_file = File.read(File.join(File.dirname(__FILE__),
          'container_lists', 'mc00000_container_list_no_series.csv' ))
    @ead_generator = Stead::EadGenerator.from_csv(csv_file, :idcontainers => true)
    @generated_ead = @ead_generator.to_ead

    @did = @generated_ead.xpath('//xmlns:c01').first
  end

  def test_component_parts_have_attributes
    containers = @did.xpath('xmlns:did/xmlns:container')
    assert containers[0].has_attribute?('id')
    assert containers[1].has_attribute?('parent')
    assert_equal containers[0].attribute('id').value, containers[1].attribute('parent').value

    assert containers[1].has_attribute?('id')
    assert containers[2].has_attribute?('parent')
    assert_equal containers[1].attribute('id').value, containers[2].attribute('parent').value
  end



end

