require 'abstract_unit'

class ActsAsIndexedTest < ActiveSupport::TestCase
  fixtures :posts

  def teardown
    # need to do this to work with the :if Proc tests.
    Post.acts_as_indexed :fields => [:title, :body]
    destroy_index
  end

  def test_adds_to_index
    original_post_count = Post.count
    assert_equal [], Post.find_with_index('badger')
    post = Post.new(:title => 'badger', :body => 'Thousands of them!')
    assert post.save
    assert_equal original_post_count + 1, Post.count
    assert_equal [post.id], result_ids('badger')
  end
  
  def test_removes_from_index
    original_post_count = Post.count
    assert_equal [posts(:wikipedia_article_4).id], result_ids('album')
    assert Post.find(posts(:wikipedia_article_4).id).destroy
    assert_equal [], result_ids('album')
    assert_equal original_post_count - 1, Post.count
  end
  
  def test_search_returns_posts
    Post.with_query('album').each do |p|
      assert_equal Post, p.class
    end
  end
  
  def test_search_returns_post_ids
    result_ids('album').each do |pid|
      assert p = Post.find(pid)
      assert_equal Post, p.class
    end
  end
  
  # After a portion of a record has been removed
  # the portion removes should no longer be in the index.
  def test_updates_index
    p = Post.create(:title => 'A special title', :body => 'foo bar bla bla bla')
    assert result_ids('title').include?(p.id)
    p.update_attributes(:title => 'No longer special')
    assert !result_ids('title').include?(p.id)
  end
  
  def test_simple_queries
    assert_equal_array_contents [],     result_ids(nil)
    assert_equal_array_contents [],     result_ids('')
    assert_equal_array_contents [5, 6], result_ids('ship')
    assert_equal_array_contents [6],    result_ids('foo')
    assert_equal_array_contents [6],    result_ids('foo ship')
    assert_equal_array_contents [6],    result_ids('ship foo')
  end
  
  def test_negative_queries
    assert_equal_array_contents [5, 6], result_ids('crane')
    assert_equal_array_contents [5],    result_ids('crane -foo')
    assert_equal_array_contents [5],    result_ids('-foo crane')
    assert_equal_array_contents [],     result_ids('-foo') #Edgecase
  end
  
  def test_quoted_queries
    assert_equal_array_contents [5], result_ids('"crane ship"')
    assert_equal_array_contents [6], result_ids('"crane big"')
    assert_equal_array_contents [],  result_ids('foo "crane ship"')
    assert_equal_array_contents [],  result_ids('"crane badger"')
  end
  
  def test_negative_quoted_queries
    assert_equal_array_contents [6], result_ids('crane -"crane ship"')
    assert_equal_array_contents [],  result_ids('-"crane big"') # Edgecase
  end
  
  def test_scoped_negative_quoted_queries
    assert_equal_array_contents [6], result_ids('crane -"crane ship"')
    assert_equal_array_contents [],  result_ids('-"crane big"') # Edgecase
  end
  
  def test_start_queries
    assert_equal_array_contents [6,5],         result_ids('ship ^crane')
    assert_equal_array_contents [6,5],         result_ids('^crane ship')
    assert_equal_array_contents [6,5],         result_ids('^ship ^crane')
    assert_equal_array_contents [6,5],         result_ids('^crane ^ship')
    assert_equal_array_contents [6,5],         result_ids('^ship crane')
    assert_equal_array_contents [6,5],         result_ids('crane ^ship')
    assert_equal_array_contents [6,5],         result_ids('^crane')
    assert_equal_array_contents [6,5],         result_ids('^cran')
    assert_equal_array_contents [6,5],         result_ids('^cra')
    assert_equal_array_contents [6,5,4],       result_ids('^cr')
    assert_equal_array_contents [6,5,4,3,2,1], result_ids('^c')
    assert_equal_array_contents [],            result_ids('^notthere')
  end
  
  def test_start_quoted_queries
    assert_equal_array_contents [6,5],         result_ids('^"crane" ship')
    assert_equal_array_contents [6,5],         result_ids('ship ^"crane"')
    assert_equal_array_contents [5],           result_ids('^"crane ship"')
    assert_equal_array_contents [5],           result_ids('^"crane shi"')
    assert_equal_array_contents [5],           result_ids('^"crane sh"')
    assert_equal_array_contents [5],           result_ids('^"crane s"')
    assert_equal_array_contents [6,5],         result_ids('^"crane "')
    assert_equal_array_contents [6,5],         result_ids('^"crane"')
    assert_equal_array_contents [6,5],         result_ids('^"cran"')
    assert_equal_array_contents [6,5],         result_ids('^"cra"')
    assert_equal_array_contents [6,5,4],       result_ids('^"cr"')
    assert_equal_array_contents [6,5,4,3,2,1], result_ids('^"c"')
  end
  
  def test_find_options
    all_results = Post.find_with_index('crane',{},{:ids_only => true})
    assert_equal 2, all_results.size
    
    first_result = Post.find_with_index('crane',{:limit => 1})
    assert_equal 1, first_result.size
    assert_equal all_results.first, first_result.first.id
  
    second_result = Post.find_with_index('crane',{:limit => 1, :offset => 1})
    assert_equal 1, second_result.size
    assert_equal all_results[1], second_result.first.id
  end
  
  # When a atom already in a record is duplicated, it removes
  # all records with that same atom from the index.
  def test_update_record_bug
    p = Post.find(6)
    assert p.update_attributes(:body => p.body + ' crane')
    assert_equal 2, result_ids('crane').size
    assert_equal 2, result_ids('ship').size
  end
  
  # If an if proc is supplied, the index should only be created if the proc evaluated true
  def test_create_if
    Post.acts_as_indexed :fields => [:title, :body], :if => Proc.new { |post| post.visible }
  
    original_post_count = Post.count
    assert_equal [], Post.find_with_index('badger', {}, { :no_query_cache => true, :ids_only => true})
    p = Post.new(:title => 'badger', :body => 'thousands of them!', :visible => true)
    assert p.save
    assert_equal original_post_count + 1, Post.count
    assert_equal [p.id], Post.find_with_index('badger', {}, { :no_query_cache => true, :ids_only => true})
  
    original_post_count = Post.count
    assert_equal [], Post.find_with_index('unicorns')
    p = Post.new(:title => 'unicorns', :body => 'there are none', :visible => false)
    assert p.save
    assert_equal original_post_count + 1, Post.count
    assert_equal [], Post.find_with_index('unicorns', {}, { :no_query_cache => true, :ids_only => true})
  end
  
  # If an index already exists, and an if proc is supplied, and the proc is true, it should still appear in the index
  def test_update_if_update
    Post.acts_as_indexed :fields => [:title, :body], :if => Proc.new { |post| post.visible }
    destroy_index
  
    assert_equal 1, Post.find_with_index('crane', {}, { :no_query_cache => true, :ids_only => true}).size
    p = Post.find(6)
    assert p.update_attributes(:visible => true)
    assert_equal 1, Post.find_with_index('crane', {}, { :no_query_cache => true, :ids_only => true}).size
  end
  
  # If an index already exists, and an if proc is supplied, and the proc is false, it should no longer appear in the index
  def test_update_if_remove
    Post.acts_as_indexed :fields => [:title, :body], :if => Proc.new { |post| post.visible }
    destroy_index
  
    assert_equal 1, Post.find_with_index('crane', {}, { :no_query_cache => true, :ids_only => true}).size
    p = Post.find(6)
    assert p.update_attributes(:visible => false)
    assert_equal 0, Post.find_with_index('crane',{},{ :no_query_cache => true, :ids_only => true}).size
  end
  
  # If an index doesn't exist, and an if proc is supplied, and the proc is true, it should appear in the index
  def test_update_if_add
    Post.acts_as_indexed :fields => [:title, :body], :if => Proc.new { |post| post.visible }
    destroy_index
  
    assert_equal 1, Post.find_with_index('crane', {}, { :no_query_cache => true, :ids_only => true}).size
    p = Post.find(5)
    assert p.update_attributes(:visible => true)
    assert_equal 2, Post.find_with_index('crane',{},{ :no_query_cache => true, :ids_only => true}).size
  end
  
  # If an index doesn't exist, and an if proc is supplied, and the proc is false, then nothing happens
  def test_update_if_not_in
    Post.acts_as_indexed :fields => [:title, :body], :if => Proc.new { |post| post.visible }
    destroy_index
  
    assert_equal 1, Post.find_with_index('crane', {}, { :no_query_cache => true, :ids_only => true}).size
    p = Post.find(5)
    assert p.update_attributes(:visible => false)
    assert_equal 1, Post.find_with_index('crane',{},{ :no_query_cache => true, :ids_only => true}).size
  end

  private
  
  def result_ids(query)
    Post.with_query(query).map { |r| r.id }
  end

  def assert_equal_array_contents(a, b)
    a.sort == b.sort
  end

end
