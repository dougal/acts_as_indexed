require 'abstract_unit'
include ActsAsIndexed

class SearchIndexTest < ActiveSupport::TestCase

  def teardown
    destroy_index
  end
  
  # Write new tests for this since most of the existing tests were concerned
  # with the storage routines which have now been moved elsewhere.
  
  private
  
  def build_search_index(fields, config)
    SearchIndex.new(fields, config)
  end
  
end
