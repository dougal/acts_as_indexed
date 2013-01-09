require 'integration_test_helper.rb'
require 'benchmark'

class RecordAdditionPerformanceTest < ActiveSupport::TestCase
  fixtures :posts

  def teardown
    # need to do this to work with the :if Proc tests.
    Post.acts_as_indexed :fields => [:title, :body]
    destroy_index
  end

  def test_addition
    iterations = 200
    puts "Record addition (x #{ iterations })"

    puts Benchmark.measure {
      iterations.times do
        posts(:wikipedia_article_1).dup.save
      end
    }
  end
end
