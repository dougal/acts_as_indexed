require 'integration_test_helper.rb'
require 'benchmark'

class RecordRemovalPerformanceTest < ActiveSupport::TestCase
  fixtures :posts

  def teardown
    # need to do this to work with the :if Proc tests.
    Post.acts_as_indexed :fields => [:title, :body]
    destroy_index
  end

  def test_removal
    iterations = 200
    puts "Record removal (x #{ iterations })"

    (iterations - Post.count).times do
      posts(:wikipedia_article_1).dup.save
    end

    puts Benchmark.measure { Post.destroy_all }
  end
end
