require 'helper'

class TestStead < Test::Unit::TestCase

  def setup
    # @xsd = Stead.xsd
    @template = Nokogiri::XML(File.read(Stead.ead_template))
    @example = Nokogiri::XML(File.read(File.join(File.dirname(__FILE__),
          'container_lists', 'mc00000-ead.xml' )))
    @output = Stead::EadGenerator.from_csv(File.read(File.join(File.dirname(__FILE__),
          'container_lists', 'mc00000_container_list_no_series.csv' )))
  end

  def test_truth
    assert true
  end

  # def test_validity_of_ead_template
  #   assert @xsd.valid?(@template)
  # end

  # def test_validity_of_ead_example_document
  #   assert @xsd.valid?(@example)
  # end

  context "optional elements to add" do
    setup do
      file = File.read(File.join(File.dirname(__FILE__),
        'container_lists', 'mc00000_container_list_no_series.csv' ))
      options = {:eadid => 'mc00000', :base_url => 'http://www.lib.ncsu.edu/findingaids'}
      @generator = Stead::EadGenerator.from_csv(file, options)
      @ead = @generator.to_ead
    end
    should "add the eadid if supplied" do
      assert_equal 'mc00000', @ead.xpath('//xmlns:eadid').first.content
    end
    should "add an ead url if supplied" do
      assert_equal 'http://www.lib.ncsu.edu/findingaids/mc00000', @ead.xpath('//xmlns:eadid').first['url']
    end
  end

end

