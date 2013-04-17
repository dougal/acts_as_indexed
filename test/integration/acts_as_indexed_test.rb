require 'integration_test_helper.rb'

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
    assert_equal [post.id], find_with_index_ids('badger')
  end

  def test_removes_from_index
    original_post_count = Post.count
    assert_equal [posts(:wikipedia_article_4).id], find_with_index_ids('album')
    assert Post.find(posts(:wikipedia_article_4).id).destroy
    assert_equal [], find_with_index_ids('album')
    assert_equal original_post_count - 1, Post.count
  end

  def test_search_returns_posts
    Post.with_query('album').each do |p|
      assert_equal Post, p.class
    end
  end

  def test_search_returns_post_ids
    find_with_index_ids('album').each do |pid|
      assert p = Post.find(pid)
      assert_equal Post, p.class
    end
  end

  # After a portion of a record has been removed
  # the portion removes should no longer be in the index.
  def test_updates_index
    p = Post.create(:title => 'A special title', :body => 'foo bar bla bla bla')
    assert find_with_index_ids('title').include?(p.id)
    p.update_attributes(:title => 'No longer special')
    assert !find_with_index_ids('title').include?(p.id)
  end

  def test_simple_queries
    queries = {
      nil        => [],
      ''         => [],
      'ship'     => [5, 6], # 5 has 3/4 occurences, 6 has 1/4.
      'crane'    => [6, 5], # 6 has 2/3 occurences, 5 has 1/3.
      'foo'      => [6],
      'foo ship' => [6],
      'ship foo' => [6]
    }

    run_queries(queries)
  end

  def test_negative_queries
    queries = {
      'crane -foo' => [5],
      '-foo crane' => [5],
      '-foo'       => [], # negative only edgecase.
      're-entered' => [5] # actually a hyphen edgecase.
    }

    run_queries(queries)
  end

  def test_quoted_queries
    queries = {
      '"crane ship"'     => [5],
      '"crane big"'      => [6],
      'foo "crane ship"' => [],
      '"crane badger"'   => []
    }

    run_queries(queries)
  end

  def test_negative_quoted_queries
    queries = {
      'crane -"crane ship"' => [6],
      '-"crane big"'        => [] # edgecase
    }

    run_queries(queries)
  end

  def test_start_queries
    queries = {
      'ship ^crane'  => [5, 6], # 5 has 3/4 + 2/3 = 17/12, 6 has 1/4 + 1/3 = 7/12
      '^crane ship'  => [5, 6], # 5 has 3/4 + 2/3 = 17/12, 6 has 1/4 + 1/3 = 7/12
      '^ship ^crane' => [5, 6], # 5 has 3/4 + 2/3 = 17/12, 6 has 1/4 + 1/3 = 7/12
      '^crane ^ship' => [5, 6], # 5 has 3/4 + 2/3 = 17/12, 6 has 1/4 + 1/3 = 7/12
      '^ship crane'  => [5, 6], # 5 has 3/4 + 2/3 = 17/12, 6 has 1/4 + 1/3 = 7/12
      'crane ^ship'  => [5, 6], # 5 has 3/4 + 2/3 = 17/12, 6 has 1/4 + 1/3 = 7/12
      '^crane'       => [6, 5], # 6 has 2/3 occurences, 5 has 1/3.
      '^cran'        => [6, 5], # 6 has 2/3 occurences, 5 has 1/3.
      '^cra'         => [6, 5], # 6 has 2/3 occurences, 5 has 1/3.
      '^cr'          => [6, 4, 5], # 6 has 2/4, 4 has 1/4, 5 has 1/4.
      '^c'           => [5, 2, 1, 3, 6, 4], # 5 has 9/25, 2 has 8/25, 1 has 1/25, 3 has 2/25, 6 has 2/25, 5 has 1/25.
      '^notthere'    => []
    }

    run_queries(queries)
  end

  def test_start_quoted_queries
    queries = {
      '^"crane" ship' => [5, 6], # 5 has 3/4 + 2/3 = 17/12, 6 has 1/4 + 1/3 = 7/12
      'ship ^"crane"' => [5, 6], # 5 has 3/4 + 2/3 = 17/12, 6 has 1/4 + 1/3 = 7/12
      '^"crane ship"' => [5],
      '^"crane shi"'  => [5],
      '^"crane sh"'   => [5],
      '^"crane s"'    => [5],
      '^"crane "'     => [6, 5], # 6 has 2/3 occurences, 5 has 1/3.
      '^"crane"'      => [6, 5], # 6 has 2/3 occurences, 5 has 1/3.
      '^"cran"'       => [6, 5], # 6 has 2/3 occurences, 5 has 1/3.
      '^"cra"'        => [6, 5], # 6 has 2/3 occurences, 5 has 1/3.
      '^"cr"'         => [6, 4, 5], # 6 has 2/4, 4 has 1/4, 5 has 1/4.
      '^"c"'          => [5, 2, 1, 3, 6, 4] # 5 has 9/25, 2 has 8/25, 1 has 1/25, 3 has 2/25, 6 has 2/25, 5 has 1/25.
    }

    run_queries(queries)
  end


  # NOTE: This test always fails for Rails 2.3. A bug somewhere in either
  #       Rails or the SQLite adaptor which causes the offset to be ignored.
  # The offending assertions are not run in CI as a result.
  def test_find_options
    # limit.
    assert_equal [6], Post.find_with_index('^cr', { :limit => 1 }, :ids_only => true)
    assert_equal [6], Post.find_with_index('^cr', { :limit => 1 }).map{ |r| r.id }

    # offset
    assert_equal [4, 5], Post.find_with_index('^cr', { :offset => 1 }, :ids_only => true)
    assert_equal [4, 5], Post.find_with_index('^cr', { :offset => 1 }).map{ |r| r.id }

    # limit and offset
    assert_equal [4], Post.find_with_index('^cr', { :limit => 1, :offset => 1 }, :ids_only => true)
    assert_equal [4], Post.find_with_index('^cr', { :limit => 1, :offset => 1 }).map{ |r| r.id }

    # order
    assert_equal [6,5,4,3,2,1], Post.find_with_index('^c', { :order => 'id desc' }).map{ |r| r.id }
    assert_equal [1,2,3,4,5,6], Post.find_with_index('^c', { :order => 'id' }).map{ |r| r.id }

    # order and limit
    assert_equal [6,5,4], Post.find_with_index('^c', { :order => 'id desc' , :limit => 3}).map{ |r| r.id }
    assert_equal [1,2,3,4], Post.find_with_index('^c', { :order => 'id', :limit => 4 }).map{ |r| r.id }

    # order, limit and offset
    assert_equal [5,4,3], Post.find_with_index('^c', { :order => 'id desc' , :limit => 3, :offset => 1}).map{ |r| r.id }
    assert_equal [3,4], Post.find_with_index('^c', { :order => 'id', :limit => 2, :offset => 2 }).map{ |r| r.id }

    # order and offset
    unless ENV['CI'] && !Post.respond_to?(:where) # Rails < 3 does not respond to arel methods.
      assert_equal [5,4,3,2,1], Post.find_with_index('^c', { :order => 'id desc' , :offset => 1}).map{ |r| r.id }
      assert_equal [3,4,5,6], Post.find_with_index('^c', { :order => 'id', :offset => 2 }).map{ |r| r.id }
    end
  end

  def test_should_error_when_ids_only_combined_with_finder_options
    expected_message = "ids_only can not be combined with find option keys other than :offset or :limit"

    error = assert_raise(ArgumentError) do
      Post.find_with_index('foo', { :order => 'id' }, :ids_only => true)
    end
    assert_equal(expected_message, error.message)

    error = assert_raise(ArgumentError) do
      Post.find_with_index('bar', { 'order' => 'id' }, :ids_only => true)
    end
    assert_equal(expected_message, error.message)
  end

  # When a atom already in a record is duplicated, it should not remove
  # all records with that same atom from the index.
  def test_update_record_bug
    p = Post.find(6)
    assert p.update_attributes(:body => p.body + ' crane')
    assert_equal 2, find_with_index_ids('crane').size
    assert_equal 2, find_with_index_ids('ship').size
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

  # If a record is not in the index, and is updated, it should still not be in the index.
  def test_update_if_not_in
    Post.acts_as_indexed :fields => [:title, :body], :if => Proc.new { |post| post.visible }
    destroy_index

    assert_equal [6], Post.find_with_index('crane', {}, { :no_query_cache => true, :ids_only => true})

    posts(:wikipedia_article_5).update_attributes(:title => 'A new title')
    assert_equal [6], Post.find_with_index('crane',{},{ :no_query_cache => true, :ids_only => true})
  end

  def test_update_if_with_external_proc
    external_truth = true
    Post.acts_as_indexed :fields => [:title, :body], :if => Proc.new { |post| external_truth }
    destroy_index

    assert_equal [6], Post.find_with_index('foo', {}, { :no_query_cache => true, :ids_only => true})

    # When the proc returns false, on update, the post should be removed from the index.
    external_truth = false
    posts(:article_similar_to_5).save
    assert_equal [], Post.find_with_index('foo', {}, { :no_query_cache => true, :ids_only => true})
  end

  def test_case_insensitive
    Post.acts_as_indexed :fields => [:title, :body], :case_sensitive => true
    destroy_index

    assert_equal 1, Post.find_with_index('Ellis', {}, { :no_query_cache => true, :ids_only => true}).size
    assert_equal 0, Post.find_with_index('ellis', {}, { :no_query_cache => true, :ids_only => true}).size

    assert_equal 3, Post.find_with_index('The', {}, { :no_query_cache => true, :ids_only => true}).size
    assert_equal 5, Post.find_with_index('the', {}, { :no_query_cache => true, :ids_only => true}).size
  end

  def test_queries_across_field_boundaries
    assert_equal [], Post.find_with_index('"Ellis Julien"', { :limit => 1 }, :ids_only => true)
    assert_equal [], Post.find_with_index('"myself crane"', { :limit => 1 }, :ids_only => true)
  end

  def test_records_with_underscores
    post_with_underscores = Post.create(:title => 'Test_try_it', :body => 'Any old thing')

    assert_equal [post_with_underscores], Post.find_with_index('try')
  end

  private

  def run_queries(queries)
    queries.each do |query, expected_results|

      actual_results = find_with_index_ids(query)
      message = "#{expected_results.inspect} expected for find_with_index(#{query.inspect}) but was\n#{actual_results.inspect}"
      assert expected_results == actual_results, message

      actual_results = find_with_index_ids_only(query)
      message = "#{expected_results.inspect} expected for find_with_index(#{query.inspect}, {}, :ids_only => true) but was\n#{actual_results.inspect}"
      assert expected_results == actual_results, message

      actual_results = find_with_query(query)
      message = "#{expected_results.inspect} expected for with_query(#{query.inspect}) but was\n#{actual_results.inspect}"
      assert expected_results.sort == actual_results.sort, message
    end
  end

  def find_with_index_ids(query)
    Post.find_with_index(query).map { |r| r.id }
  end

  def find_with_index_ids_only(query)
    Post.find_with_index(query, {}, :ids_only => true)
  end

  def find_with_query(query)
    Post.with_query(query).map { |r| r.id }
  end

end
