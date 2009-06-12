require File.dirname(__FILE__) + '/abstract_unit'
include Foo::Acts::Indexed

class SearchIndexTest < ActiveSupport::TestCase

  def teardown
    destroy_index
  end

  def test_should_check_for_non_existing_index
    File.expects(:exists?).at_least_once.with(index_loc).returns(false)
    File.expects(:open).never
    assert build_search_index
  end

  def test_should_check_for_existing_index
    File.stubs(:exists?).with(index_loc).returns(true)
    File.expects(:open).with(File.join(index_loc, 'size')) # TODO: Test the marshall in the block.
    assert build_search_index
  end
  
  private
  
  def build_search_index(root = index_loc, index_depth = 2, fields = [:title, :body], min_word_size = 3)
    SearchIndex.new([root], index_depth, fields, min_word_size)
  end
  
end
