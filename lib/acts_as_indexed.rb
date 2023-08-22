require 'active_record'

path = File.expand_path(File.dirname(__FILE__))
$:.unshift path unless $:.include?(path)
require 'acts_as_indexed/class_methods'
require 'acts_as_indexed/instance_methods'
require 'acts_as_indexed/singleton_methods'
require 'acts_as_indexed/configuration'
require 'acts_as_indexed/search_index'
require 'acts_as_indexed/search_atom'
require 'acts_as_indexed/storage'
require 'acts_as_indexed/pre_tokenizer'
require 'acts_as_indexed/tokenizer'
require 'acts_as_indexed/token_normalizer'

if defined?(WillPaginate)
  require 'will_paginate_search'
end

module ActsAsIndexed #:nodoc:

  # This is the last version of the plugin where the index structure was
  # changed in some manner. Is only changed when necessary, not every release.
  INDEX_VERSION = '0.6.8'

  # Holds the default configuration for acts_as_indexed.

  @configuration = Configuration.new

  # Returns the current configuration for acts_as_indexed.

  def self.configuration
    @configuration
  end

  # Call this method to modify defaults in your initializers.
  #
  # Example showing some defaults:
  #   ActsAsIndexed.configure do |config|
  #     config.index_file = [Rails.root,'index']
  #     config.index_file_depth = 3
  #     config.min_word_size = 3
  #   end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
  end

  def self.included(mod)
    mod.extend(ClassMethods)
  end

end

# reopen ActiveRecord and include all the above to make
# them available to all our models if they want it

ActiveRecord::Base.class_eval do
  include ActsAsIndexed
end
