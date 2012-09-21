module ActsAsIndexed

  module ClassMethods

    # Declares a class as searchable.
    #
    # ====options:
    # fields:: Names of fields to include in the index. Symbols pointing to
    #          instance methods of your model may also be given here.
    # index_file_depth:: Tuning value for the index partitioning. Larger
    #                    values result in quicker searches, but slower
    #                    indexing. Default is 3.
    # min_word_size:: Sets the minimum length for a word in a query. Words
    #                 shorter than this value are ignored in searches
    #                 unless preceded by the '+' operator. Default is 3.
    # index_file:: Sets the location for the index. By default this is
    #              RAILS_ROOT/tmp/index. Specify as an array. The default, for
    #              example, would be set as [Rails.root,'tmp','index].

    def acts_as_indexed(options = {})
      class_eval do
        extend ActsAsIndexed::SingletonMethods
      end
      include ActsAsIndexed::InstanceMethods

      after_create  :add_to_index
      before_update :update_index
      after_destroy :remove_from_index

      # scope for Rails 3.x, named_scope for Rails 2.x.
      if self.respond_to?(:where)
        scope :with_query, lambda { |query| where("#{table_name}.#{primary_key} IN (?)", search_index(query, {}, {:ids_only => true})) }
      else
        named_scope :with_query, lambda { |query| { :conditions => ["#{table_name}.#{primary_key} IN (?)", search_index(query, {}, {:ids_only => true}) ] } }
      end

      cattr_accessor :aai_config, :aai_fields

      self.aai_fields = options.delete(:fields)
      raise(ArgumentError, 'no fields specified') if self.aai_fields.nil? || self.aai_fields.empty?

      self.aai_config = ActsAsIndexed.configuration.dup
      self.aai_config.if_proc = options.delete(:if)
      options.each do |k, v|
        self.aai_config.send("#{k}=", v)
      end

      # Add the Rails environment and this model's name to the index file path.
      self.aai_config.index_file = self.aai_config.index_file.join(Rails.env, self.name.underscore)
    end

    # Adds the passed +record+ to the index. Index is built if it does not already exist. Clears the query cache.

    def index_add(record)
      return if self.aai_config.disable_auto_indexing

      build_index
      index = new_index
      index.add_record(record)
      @query_cache = {}
    end

    # Removes the passed +record+ from the index. Clears the query cache.

    def index_remove(record)
      return if self.aai_config.disable_auto_indexing

      index = new_index
      index.remove_record(record)
      @query_cache = {}
    end

    # Updates the index.
    # 1. Removes the previous version of the record from the index
    # 2. Adds the new version to the index.

    def index_update(record)
      return if self.aai_config.disable_auto_indexing

      build_index
      index = new_index
      index.update_record(record,find(record.id))
      @query_cache = {}
    end

    # Finds instances matching the terms passed in +query+. Terms are ANDed by
    # default. Returns an array of model instances or, if +ids_only+ is
    # true, an array of integer IDs.
    #
    # Keeps a cache of matched IDs for the current session to speed up
    # multiple identical searches.
    #
    # ====find_options
    # Same as ActiveRecord#find options hash. An :order key will override
    # the relevance ranking
    #
    # ====options
    # ids_only:: Method returns an array of integer IDs when set to true.
    # no_query_cache:: Turns off the query cache when set to true. Useful for testing.

    def search_index(query, find_options={}, options={})

      # Clear the query cache off  if the key is set.
      @query_cache = {}  if options[:no_query_cache]

      # Run the query if not already in cache.
      if !@query_cache || !@query_cache[query]
        build_index
        (@query_cache ||= {})[query] = new_index.search(query)
      end

      if options[:ids_only]
        find_option_keys = find_options.keys.map{ |k| k.to_sym }
        find_option_keys -= [:limit, :offset]
        if find_option_keys.any?
          raise ArgumentError, 'ids_only can not be combined with find option keys other than :offset or :limit'
        end
      end

      if find_options.include?(:order)
        part_query = @query_cache[query].map{ |r| r.first }

      else
        # slice up the results by offset and limit
        offset = find_options[:offset] || 0
        limit = find_options.include?(:limit) ? find_options[:limit] : @query_cache[query].size
        part_query = sort(@query_cache[query]).slice(offset,limit).map{ |r| r.first }

        # Set these to nil as we are dealing with the pagination by setting
        # exactly what records we want.
        find_options[:offset] = nil
        find_options[:limit] = nil
      end

      return part_query if options[:ids_only]

      with_scope :find => find_options do
        # Doing the find like this eliminates the possibility of errors occuring
        # on either missing records (out-of-sync) or an empty results array.
        records = find(:all, :conditions => [ "#{table_name}.#{primary_key} IN (?)", part_query])

        if find_options.include?(:order)
         records # Just return the records without ranking them.

         else
           # Results come back in random order from SQL, so order again.
           ranked_records = ActiveSupport::OrderedHash.new
           records.each do |r|
             ranked_records[r] = @query_cache[query][r.id]
           end

           sort(ranked_records.to_a).map{ |r| r.first }
         end
      end

    end

    # Builds an index from scratch for the current model class.
    # Does not run if the index already exists.

    def build_index
      return if aai_config.index_file.directory?

      index = new_index
      find_in_batches({ :batch_size => 500 }) do |records|
        index.add_records(records)
      end
    end

    private

    # If two records or record IDs have the same rank, sort them by ID.
    # This prevents a different order being returned by different Rubies.
    def sort(ranked_records)
      ranked_records.sort { |a, b|
        a_score = a.last
        a_id = a.first.is_a?(Fixnum) ? a.first : a.first.id

        b_score = b.last
        b_id = b.first.is_a?(Fixnum) ? b.first : b.first.id

        if a_score == b_score
          a_id <=> b_id
        else
          b_score <=> a_score # We want the records with better relevance first.
        end

      }
    end

    def new_index
      SearchIndex.new(aai_fields, aai_config)
    end

  end

end