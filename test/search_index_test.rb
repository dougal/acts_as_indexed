require 'abstract_unit'
include ActsAsIndexed

class SearchIndexTest < ActiveSupport::TestCase

  def teardown
    destroy_index
  end
  
  # Write new tests for this since most of the existing tests were concerned
  # with the storage routines which have now been moved elsewhere.
  
  private
  
  def build_search_index(root = index_loc, index_depth = 2, fields = [:title, :body], min_word_size = 3)
    SearchIndex.new([root], index_depth, fields, min_word_size)
  end
  
end
