require File.dirname(__FILE__) + '/abstract_unit'

class ActsAsIndexedTest < Test::Unit::TestCase
  fixtures :posts
  
  def setup
    destroy_index
  end
  
  def teardown
    destroy_index
  end
  
  def test_generates_index_on_first_query
    assert !File.exists?(File.join(File.dirname(__FILE__),'index'))
    assert_equal [], Post.find_with_index('badger')
    assert File.exists?(File.join(File.dirname(__FILE__),'index'))
    assert File.exists?(File.join(File.dirname(__FILE__),'index','development'))
    assert File.exists?(File.join(File.dirname(__FILE__),'index','development','post'))
  end
  
  def test_adds_to_index
    original_post_count = Post.count
    assert_equal [], Post.find_with_index('badger')
    p = Post.new(:title => 'badger', :body => 'Thousands of them!')
    assert p.save
    assert_equal original_post_count+1, Post.count
    assert_equal [p.id], Post.find_with_index('badger',true)
  end
  
  def test_removes_from_index
    original_post_count = Post.count
    assert_equal [posts(:wikipedia_article_4).id], Post.find_with_index('album',true)
    assert Post.find(posts(:wikipedia_article_4).id).destroy
    assert_equal [], Post.find_with_index('album',true)
    assert_equal original_post_count-1, Post.count
  end
  
  def test_search_returns_posts
    Post.find_with_index('album').each do |p|
      assert_equal Post, p.class
    end
  end
  
  def test_search_returns_post_ids
    Post.find_with_index('album',true).each do |pid|
      assert p = Post.find(pid)
      assert_equal Post, p.class
    end
  end
  
  def test_simple_queries
    assert_equal [5, 6],  Post.find_with_index('ship',true).sort
    assert_equal [6],  Post.find_with_index('foo',true)
    assert_equal [6],  Post.find_with_index('foo ship',true)
    assert_equal [6],  Post.find_with_index('ship foo',true)
  end
  
  def test_negative_queries
    assert_equal [5, 6],  Post.find_with_index('crane',true).sort
    assert_equal [5],  Post.find_with_index('crane -foo',true)
    assert_equal [5],  Post.find_with_index('-foo crane',true)
    assert_equal [],  Post.find_with_index('-foo',true) #Edgecase
  end

  def test_quoted_queries
    assert_equal [5],  Post.find_with_index('"crane ship"',true)
    assert_equal [6],  Post.find_with_index('"crane big"',true)
    assert_equal [],  Post.find_with_index('foo "crane ship"',true)
    assert_equal [],  Post.find_with_index('"crane badger"',true)
  end
  
  def test_negative_quoted_queries
    assert_equal [6],  Post.find_with_index('crane -"crane ship"',true)
    assert_equal [],  Post.find_with_index('-"crane big"',true) # Edgecase
  end
  
end
