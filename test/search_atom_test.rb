require File.dirname(__FILE__) + '/abstract_unit'
include Foo::Acts::Indexed

class SearchAtomTest < ActiveSupport::TestCase
  
  @search_atom = SearchAtom.new
  
  
  def test_should_create_a_new_instance
    assert SearchAtom.new
  end
  
  def test_include_record_should_return_false
    assert ! SearchAtom.new.include_record?(123)
  end
  
  def test_include_record_should_return_true
    assert build_search_atom.include_record?(123)
  end
  
  def test_add_record_should_add_record
    search_atom = SearchAtom.new
    search_atom.add_record(456)
    
    assert search_atom.include_record?(456)
  end
  
  def test_add_record_should_leave_positions_untouched
    search_atom = build_search_atom
    original_records_count = search_atom.record_ids.size
    
    search_atom.add_record(123)
    assert_equal original_records_count, search_atom.record_ids.size
    assert_equal [2,23,78], search_atom.positions(123)
  end
  
  private
  
  def build_search_atom(records = { 123 => [2,23,78] })
    search_atom = SearchAtom.new
    records.each do |record_id, positions|
      search_atom.add_record(record_id)
      positions.each do |position|
        search_atom.add_position(record_id, position)
      end
    end
    search_atom
  end
  
end
