require File.dirname(__FILE__) + '/abstract_unit'

class IndexedModelsTest < ActiveSupport::TestCase
  fixtures :posts, :sources

  def teardown
    destroy_index
  end

  def test_models_regester_themselves
    assert IndexedModels.registered_models.include? Post
    assert IndexedModels.registered_models.include? Source
  end

  def test_search_across_models
    results = IndexedModels.with_query "service"
    assert_equal results.size, 2 # two models
    results.flatten!
    assert_equal results.size, 2 # two results total
    results.delete_if {|r|r.is_a? Post}
    assert_equal results.size, 1
    results.delete_if {|r|r.is_a? Source}
    assert_equal results.size, 0
  end

  def test_search_across_models_with_nonarray_except
    results = IndexedModels.with_query "service", :except => :post
    results.flatten!
    assert_equal results.size, 1
    assert_equal results.first.class.name, 'Source'
  end

  def test_search_across_models_with_plural_except
    results = IndexedModels.with_query "service", :except => [:posts]
    results.flatten!
    assert_equal results.size, 1
    assert_equal results.first.class.name, 'Source'
  end

  def test_search_across_models_with_multiple_except
    results = IndexedModels.with_query "service", :except => [:post, :source]
    results.flatten!
    assert_equal results.size, 0
  end

  def test_search_across_models_with_only
    results = IndexedModels.with_query "service", :only => :post
    results.flatten!
    assert_equal results.size, 1
    assert_equal results.first.class.name, 'Post'
  end

  def test_search_across_models_with_empty_only
    results = IndexedModels.with_query "service", :only => []
    results.flatten!
    assert_equal results.size, 0
  end

end
