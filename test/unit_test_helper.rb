require 'test/unit'
require 'fileutils'
require 'rubygems'

require 'bundler/setup'
require 'mocha'

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

test_path = Pathname.new(File.expand_path('../', __FILE__))
require test_path.parent.join('lib', 'acts_as_indexed').to_s
