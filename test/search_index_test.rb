require File.dirname(__FILE__) + '/abstract_unit'
include ActsAsIndexed

class SearchIndexTest < ActiveSupport::TestCase

  def teardown
    destroy_index
  end

  def test_should_check_for_non_existing_index
    SearchIndex.any_instance.expects(:exists?).returns(false)
    File.expects(:open).never
    assert build_search_index
  end

  def test_should_check_for_existing_index
    SearchIndex.any_instance.expects(:exists?).returns(true)
    SearchIndex.any_instance.expects(:load_record_size).returns(0)
    assert build_search_index
  end
  
  def test_add_record
    search_index = build_search_index
    mock_record = mock(:id => 123)
    mock_condensed_record = ['mock','condensed','record']
    
    search_index.expects(:condense_record).with(mock_record).returns(mock_condensed_record)
    search_index.expects(:load_atoms).with(mock_condensed_record)
    search_index.expects(:add_occurences).with(mock_condensed_record,123)
    
    search_index.add_record(mock_record)
  end
  
  def test_add_records
    search_index = build_search_index
    mock_records = ['record0', 'record1']
    
    search_index.expects(:add_record).with('record0')
    search_index.expects(:add_record).with('record1')
    
    search_index.add_records(mock_records)
  end
  
  private
  
  def build_search_index(root = index_loc, index_depth = 2, fields = [:title, :body], min_word_size = 3)
    SearchIndex.new([root], index_depth, fields, min_word_size)
  end
  
end
