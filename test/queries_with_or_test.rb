require 'abstract_unit'

class QueriesWithOrTest < ActiveSupport::TestCase
  fixtures :posts

  def setup
    Post.acts_as_indexed :fields => [:title, :body], :default_operator => :or
  end

  def test_simple_queries
    queries = {
      nil        => [],
      ''         => [],
      'ship'     => [5,6],
      'crane'    => [6,5],
      'foo'      => [6],
      'foo ship' => [5,6],
      'ship foo' => [5,6]
    }

    run_queries(queries)
  end

  def test_negative_queries
    queries = {
      'crane -foo' => [5],
      '-foo crane' => [5],
      '-foo'       => [] # edgecase
    }

    run_queries(queries)
  end

  def test_multiple_negative_queries
    queries = {
      'crane -foo -ship' => [],
      'crane -foo -album' => [5]
    }

    run_queries(queries)
  end
  
  def test_quoted_queries
    queries = {
      '"crane ship"'     => [5],
      '"crane big"'      => [6],
      'foo "crane ship"' => [5,6],
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

  def test_multiple_negative_quoted_queries
    queries = {
      'crane -"crane ship" -album' => [6],
      'crane -"crane ship" -"west side and"' => [6],
      'crane -"crane ship" -"ready reserve"' => [6],
      'crane -"crane ship" -"big ship"' => []
    }

    run_queries(queries)
  end

  def test_scoped_negative_quoted_queries
    queries = {
      'crane -"crane ship"' => [6],
      '-"crane big"'        => []
    }

    run_queries(queries)
  end

  def test_start_queries
    queries = {
      'ship ^crane'  => [5,6],
      '^crane ship'  => [5,6],
      '^ship ^crane' => [5,6],
      '^crane ^ship' => [5,6],
      '^ship crane'  => [5,6],
      'crane ^ship'  => [5,6],
      '^crane'       => [6,5] ,
      '^cran'        => [6,5],
      '^cra'         => [6,5],
      '^cr'          => [6,5,4],
      '^c'           => [5,2,1,6,3,4],
      '^notthere'    => []
    }

    run_queries(queries)
  end

  def test_start_quoted_queries
    queries = {
      '^"crane" ship' => [5,6],
      'ship ^"crane"' => [5,6],
      '^"crane ship"' => [5],
      '^"crane shi"'  => [5],
      '^"crane sh"'   => [5],
      '^"crane s"'    => [5],
      '^"crane "'     => [6,5],
      '^"crane"'      => [6,5],
      '^"cran"'       => [6,5],
      '^"cra"'        => [6,5],
      '^"cr"'         => [6,5,4],
      '^"c"'          => [5,2,1,6,3,4],
    }

    run_queries(queries)
  end

  def test_positive_queries
    queries = {
      'crane +was' => [5,2,4,1],
      '+crane was' => [5,6],
      '+was +crane' => [5],
      '+crane +album' => []
    }

    run_queries(queries)
  end

  def test_complex_queries
    queries = {
      'games +was -album -Draft' => [5,1]
    }

    run_queries(queries)
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
