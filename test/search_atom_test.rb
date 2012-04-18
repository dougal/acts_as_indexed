require 'abstract_unit'
include ActsAsIndexed

class SearchAtomTest < ActiveSupport::TestCase  
  
  def test_should_create_a_new_instance
    assert SearchAtom.new
  end
  
  def test_include_record_should_return_false
    assert ! SearchAtom.new.include_record?(123)
  end
  
  def test_include_record_should_return_true
    assert build_search_atom.include_record?(123)
  end
  
  def test_add_token_should_add_token
    search_atom = SearchAtom.new
    search_atom.add_token('token')
    
    assert search_atom.include_token?('token')
  end

  def test_add_record_token_should_add_record
    search_atom = SearchAtom.new
    search_atom.add_record_token('token', 123)

    assert search_atom.include_record?(123)
  end
  
  def test_add_record_should_leave_positions_untouched
    search_atom = build_search_atom
    original_records_count = search_atom.record_ids.size
    search_atom.add_record_token('examples', 112)
    exact = search_atom.exact('example')
    assert_equal original_records_count, exact.record_ids.size
    assert_equal [2,23,78], search_atom.records_by_token('example')[123]
  end
  
  def test_add_position_should_add_position
    search_atom = build_search_atom
    search_atom.expects(:add_token).with('example')
    
    search_atom.add_position(123, 'example', 98)
    assert search_atom.all_positions(123).include?(98)
  end
  
  def test_record_ids_should_return_obvious
    assert_equal [123], build_search_atom.record_ids
  end
  
  def test_all_positions_should_return_positions
    assert_equal [2,23,78], build_search_atom.all_positions(123)
  end
  
  def test_all_positions_should_return_nil
    assert_equal nil, build_search_atom.all_positions(456)
  end
  
  def test_remove_record
    search_atom = build_search_atom
    search_atom.remove_record(123)
    assert ! search_atom.include_record?(123)
  end
  
  def test_preceded_by
    former = build_search_atom({ 'example' => { 1 => [1], 2 => [1] }})
    latter = build_search_atom({ 'example' => { 1 => [2], 2 => [3] }})
    result = latter.preceded_by(former)
    assert_equal [1], result.record_ids
    assert_equal [2], result.all_positions(1)
  end
  
  def test_weightings
    # 5 documents.
    weightings = build_search_atom({'example' => { 1 => [1, 8], 2 => [1] }}).weightings(5)
    assert_in_delta(1.832, weightings[1], 2 ** -10)
    assert_in_delta(0.916, weightings[2], 2 ** -10)
    
    # 10 documents.
    weightings = build_search_atom({'example' => { 1 => [1, 8], 2 => [1] }}).weightings(10)
    assert_in_delta(3.219, weightings[1], 2 ** -10)
    assert_in_delta(1.609, weightings[2], 2 ** -10)
  end

  def test_adding_with_recursive_merge
    sa0 = SearchAtom.new()
    sa1 = SearchAtom.new({'example' => {1=>[1]}})
    sa2 = SearchAtom.new({'example' => {1=>[2], 2=>[3]}})
    
    assert_equal (sa0 + sa1).records, {'example' => {1=>[1]}}
    assert_equal (sa0 + sa2).records, {'example' => {1=>[2], 2=>[3]}}
    
    assert_equal (sa1 + sa2).records, {'example' => {1=>[1,2], 2=>[3]}}
    assert_equal (sa2 + sa1).records, {'example' => {1=>[2,1], 2=>[3]}}
  end


  def test_adding_with_recursive_merge_multiword
    sa1 = SearchAtom.new({'example' => {1=>[1]}})
    sa2 = SearchAtom.new({'examples' => {1=>[2], 2=>[3]}})

    assert_equal (sa1 + sa2).records, {'example' => {1=>[1]},
      'examples' =>{1=>[2], 2=>[3]}}

    assert_equal (sa2 + sa1).records, {'example' => {1=>[1]},
      'examples' =>{1=>[2], 2=>[3]}}

  end
  
  private
  
  def build_search_atom(atoms = { 'example' => {123 => [2,23,78] }})
    search_atom = SearchAtom.new
    atoms.each do |token, records|
      records.each do |record_id, positions|
        positions.each do |position|
          search_atom.add_position(record_id, token, position)
        end
      end
    end
    search_atom
  end
  
end
