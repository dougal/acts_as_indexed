require 'integration_test_helper.rb'
require 'benchmark'

class RecordUpdatePerformanceTest < ActiveSupport::TestCase
  fixtures :posts

  QUERIES = [
    ['crane', 10_000],
    ['foo', 10_000],
    ['-foo', 10_000],
    ['-foo crane', 10_000],
    ['foo "crane ship', 10_000],
    ['crane -"crane ship"', 10_000],
    ['^cran', 10_000],
    ['ship ^cran', 10_000],
    ['^"crane" ship', 10_000],
    ['^"crane"', 10_000]
  ]

  def teardown
    # need to do this to work with the :if Proc tests.
    Post.acts_as_indexed :fields => [:title, :body]
    destroy_index
  end

  def test_queries_without_cache
    QUERIES.each do |query|
      run_query(*query, true)
    end
  end

  def test_queries_with_cache
    QUERIES.each do |query|
      run_query(query[0], query[1], false)
    end
  end

  def run_query(query, iterations, no_query_cache)
    puts "Benchmarking query #{query} with#{ 'out' if no_query_cache } cache (x #{iterations})"
    puts Benchmark.measure {
      iterations.times do
        Post.find_with_index(query, {}, :ids_only => true, :no_query_cache => no_query_cache)
      end
    }
  end

end
