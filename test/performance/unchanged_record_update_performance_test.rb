require 'integration_test_helper.rb'
require 'benchmark'

class UnchangedRecordUpdatePerformance < ActiveSupport::TestCase
  fixtures :posts

  def teardown
    # need to do this to work with the :if Proc tests.
    Post.acts_as_indexed :fields => [:title, :body]
    destroy_index
  end

  def test_updates_index
    puts "Unchanged record update (x 10000)"
    puts Benchmark.measure { 10000.times { posts(:wikipedia_article_1).save } }
  end
end
