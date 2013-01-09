require 'integration_test_helper.rb'
require 'benchmark'

class RecordUpdatePerformanceTest < ActiveSupport::TestCase
  fixtures :posts

  def teardown
    # need to do this to work with the :if Proc tests.
    Post.acts_as_indexed :fields => [:title, :body]
    destroy_index
  end

  def test_unchanged
    iterations = 10_000
    puts "Unchanged record update (x #{ iterations })"

    puts Benchmark.measure { iterations.times { posts(:wikipedia_article_1).save } }
  end

  def test_changed
    iterations = 200
    puts "Changed record update (x #{ iterations })"

    original_title = posts(:wikipedia_article_1).title

    puts Benchmark.measure {
      iterations.times do |index|
        posts(:wikipedia_article_1).update_attribute(:title, "#{original_title} #{ index }")
      end
    }
  end

  def test_unchanged_with_false_if_proc
    iterations = 200
    puts "Unchanged record update with false if_proc (x #{ iterations })"

    Post.acts_as_indexed :fields => [:title, :body], :if => Proc.new { |post| post.visible }


    puts Benchmark.measure { iterations.times { posts(:wikipedia_article_5).save } }
  end
end
