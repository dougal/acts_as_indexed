module ActsAsIndexed
  # Used to set up and modify settings for acts_as_indexed.
  class Configuration

    # Sets the location for the index. Specify as an array. The default, for
    # example, would be set as [Rails.root,'tmp','index].
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

    # Disable indexing, useful for large test suites.
    # Set to false to disable.
    # Default is false.
    attr_accessor :disable_auto_indexing

    # Disable advanced features not compatible with the Windows filesystem.
    # Set to true to disable.
    # Default is guessed depending on current platform.
    attr_writer :is_windows_filesystem

    def initialize
      @index_file       = nil
      @index_file_depth = 3
      @min_word_size    = 3
      @if_proc          = if_proc
      @case_sensitive   = false
      @disable_auto_indexing = false
      @is_windows_filesystem = RUBY_PLATFORM[/mswin32|mingw|cygwin/]
    end

    # Since we cannot expect Rails to be available on load, it is best to put
    # off setting the index_file attribute until as late as possible.
    def index_file
      @index_file ||= Rails.root.join('tmp', 'index')
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

    def is_windows_filesystem?
      !!@is_windows_filesystem
    end

  end
end
