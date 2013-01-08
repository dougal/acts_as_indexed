require 'integration_test_helper.rb'

class WillPaginateSearchTest < ActiveSupport::TestCase
  fixtures :posts

  def teardown
    # need to do this to work with the :if Proc tests.
    Post.acts_as_indexed :fields => [:title, :body]
    destroy_index
  end

  def test_paginate_search

    assert_equal [5, 2, 1, 3, 6, 4], paginate_search(1, 10)
    assert_equal [5, 2, 1], paginate_search(1, 3)
    assert_equal [3, 6, 4], paginate_search(2, 3)
  end

  private

  # Returns relevant IDs.
  def paginate_search(page, per_page)
    Post.paginate_search('^c', :page => page, :per_page => per_page).map { |p| p.id }
  end

end