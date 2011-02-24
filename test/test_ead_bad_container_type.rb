require 'helper'

class TestSteadErrors < Test::Unit::TestCase

  def setup
    @ead_generator = Stead::EadGenerator.from_csv(File.read(File.join(File.dirname(__FILE__),
          'container_lists', 'mc00000_container_list_bad_container_type.csv' )))
    @ead_generator_good = Stead::EadGenerator.from_csv(File.read(File.join(File.dirname(__FILE__),
          'container_lists', 'mc00000_container_list_no_series.csv' )))
  end

  def test_bad_container_type_raises
    assert_raise(Stead::InvalidContainerType) {@ead_generator.to_ead}
  end

  def test_bad_container_type_error_message
    begin
      @ead_generator.to_ead
    rescue Stead::InvalidContainerType => error
      assert_equal '"Box"', error.message
    end
  end

  # create an invalid ead document so that we can test that validation of the ead
  # is working
  def test_invalid_ead_error_message
    assert_raise(Stead::InvalidEad) {
      @ead_generator_good.to_ead
      a = Nokogiri::XML::Node.new('asdfasd', @ead_generator_good.ead)
      @ead_generator_good.ead.xpath('//xmlns:archdesc').first.add_child(a)
      @ead_generator_good.valid?
    }
  end

  def test_csv_with_nil_header
    assert_raise(Stead::InvalidCsv) {
      Stead::EadGenerator.from_csv(File.read(File.join(File.dirname(__FILE__),
            'container_lists', 'mc00084_container_list_empty_header.csv' ))) }
  end

end

