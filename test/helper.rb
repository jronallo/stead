require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'ruby-debug'
require 'equivalent-xml'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'stead'

class Test::Unit::TestCase
end

module SteadTestHelpers
  def assert_main_elements_equal(did, example_did)
    ['unitid', 'unittitle', 'unitdate', 'extent', 'container'].each do |elem|
      #puts example_did.xpath('.//xmlns:' + elem)
      if !example_did.xpath('.//xmlns:' + elem).empty?
        did_content = did.xpath('.//xmlns:' + elem).first.content
        assert_not_nil did_content
        assert_equal example_did.xpath('.//xmlns:' + elem).first.content,
          did_content
      end
    end
  end
end

