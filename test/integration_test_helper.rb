require 'test/unit'
require 'fileutils'
require 'rubygems'

require 'bundler/setup'
require 'active_record'
require 'active_record/fixtures'
require 'mocha'

puts "ActiveRecord version is #{ActiveRecord::VERSION::STRING}"

# Mock out the required environment variables.
# Do this before requiring AAI.
class Rails
  def self.root
    Pathname.new(Dir.pwd)
  end
  def self.env
    'test'
  end
end

# Load will_paginate.
require 'will_paginate'
require 'will_paginate/collection'

test_path = Pathname.new(File.expand_path('../', __FILE__))
require test_path.parent.join('lib', 'acts_as_indexed').to_s

ActiveRecord::Base.logger = Logger.new(test_path.join('test.log').to_s)
ActiveRecord::Base.configurations = YAML::load(IO.read(test_path.join('config', 'database.yml').to_s))
ActiveRecord::Base.establish_connection(ENV['DB'] || 'sqlite3')

# Load Schema
load(test_path.join('db', 'schema.rb').to_s)

# Load model.
$LOAD_PATH.unshift(test_path.join('fixtures').to_s)

class ActiveSupport::TestCase #:nodoc:
  include ActiveRecord::TestFixtures
  self.fixture_path = Pathname.new(File.expand_path('../', __FILE__)).join('fixtures').to_s
  self.use_transactional_fixtures = true
  self.use_instantiated_fixtures  = false

  def destroy_index
    FileUtils.rm_rf(index_loc)
  end

  def build_index
    # Makes a query to invoke the index build.
    assert_equal [], Post.find_with_index('badger')
    assert index_loc.exist?
  end

  def index_loc
    Rails.root.join('tmp', 'index')
  end

end
