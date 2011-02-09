# ActsAsIndexed
# Copyright (c) 2007 - 2011 Douglas F Shearer.
# http://douglasfshearer.com
# Distributed under the MIT license as included with this plugin.

module ActsAsIndexed
  # Used to set up and modify settings for acts_as_indexed.
  class Configuration

    # Sets the location for the index. Specify as an array. Heroku, for
    # example would use RAILS_ROOT/tmp/index, which would be set as
    # [Rails.root,'tmp','index]
    attr_accessor :index_file

    # Tuning value for the index partitioning. Larger values result in quicker
    # searches, but slower indexing. Default is 3.
    attr_reader :index_file_depth

    # Sets the minimum length for a word in a query. Words shorter than this
    # value are ignored in searches unless preceded by the '+' operator.
    # Default is 3.
    attr_reader :min_word_size

    # Proc that allows you to turn on or off index for a record.
    # Useful if you don't want an object to be placed in the index, such as a
    # draft post.
    attr_accessor :if_proc

    # Enable or disable case sensitivity.
    # Set to true to enable.
    # Default is false.
    attr_accessor :case_sensitive

    # Enable or disable thread safety.
    #
    # Disabling thread safety comes with a small (~2.5x) write-performance
    # boost, but comes at the risk of index corruption in an environment where
    # concurrent writes are numerous.
    #
    # If you have multiple processes accessing the same index (Passenger,
    # Mongrels, Unicorn) it is recommended that you leave this as-is.
    #
    # If the index is only used by one process at any one time (Heroku), then
    # this can safely be set to false. This is the recommended setting for
    # Heroku.
    #
    # Default is true.
    attr_accessor :threadsafe

    def initialize
      @index_file       = nil
      @index_file_depth = 3
      @min_word_size    = 3
      @if_proc          = if_proc
      @case_sensitive   = false
      @threadsafe       = true
    end

    # Since we cannot expect Rails to be available on load, it is best to put
    # off setting the index_file attribute until as late as possible.
    def index_file
      if @index_file.nil?
        @index_file = default_index_file
      end
      @index_file
    end

    def index_file=(file_path)
      # Under the old syntax this was an array of path parts.
      # If this is still using the array then rewrite to a Pathname.
      if file_path.is_a?(Pathname)
        @index_file = file_path
      else
        @index_file = Pathname.new(file_path.collect{|part| part.to_s}.join(File::SEPARATOR))
      end
    end

    def index_file_depth=(val)
      raise(ArgumentError, 'index_file_depth cannot be less than one (1)') if val < 1
      @index_file_depth = val
    end

    def min_word_size=(val)
      raise(ArgumentError, 'min_word_size cannot be less than one (1)') if val < 1
      @min_word_size = val
    end

    def if_proc
      @if_proc ||= Proc.new{true}
    end

    private

    def default_index_file
      if Rails.root.writable?
        Rails.root.join('index')
      else
        Rails.root.join('tmp', 'index')
      end
    end

  end
end
