# ActsAsIndexed
# Copyright (c) 2007 Douglas F Shearer.
# http://douglasfshearer.com
# Distributed under the MIT license as included with this plugin.

require 'active_record'

module Foo
  module Acts #:nodoc:
    module Indexed #:nodoc:
      
      require 'search_index'
      require 'search_atom'
      
      def self.included(mod)
        mod.extend(ClassMethods)
      end

      module ClassMethods

        def acts_as_indexed(options = {})
          class_eval do
            extend Foo::Acts::Indexed::SingletonMethods
          end
          include Foo::Acts::Indexed::InstanceMethods

          after_create  :add_to_index
          after_update  :update_index
          after_destroy :remove_from_index

          cattr_accessor :aai_config

          # default config
          self.aai_config = { 
            :index_file => [RAILS_ROOT,'index',RAILS_ENV,name],
            :index_file_depth => 3,
            :min_word_size => 3,
            :fields => []
          }

          # set fields
          aai_config[:fields] = options[:fields] if options.include?(:fields)

          # set minimum word size if available.
          aai_config[:min_word_size] = options[:min_word_size] if options.include?(:min_word_size)

          # set index file depth if available.
          # Min size of 1.
          aai_config[:index_file_depth] = options[:index_file_depth].to_i if options.include?(:index_file_depth) && options[:index_file_depth].to_i > 0

          # Set file location for plugin testing.
          # TODO: Find more portable (ruby) way of doing the up-one-level.
          aai_config[:index_file] = [File.dirname(__FILE__),'../test/index',RAILS_ENV,name] if options.include?(:self_test)

        end

        def index_add(record)
          index = SearchIndex.new(aai_config[:index_file], aai_config[:index_file_depth], aai_config[:fields], aai_config[:min_word_size])
          build_index if !index.root_exists?
          index.add_record(record)
          index.save
          @results_cache = {}
          true
        end

        def index_remove(record)
          index = SearchIndex.new(aai_config[:index_file], aai_config[:index_file_depth], aai_config[:fields], aai_config[:min_word_size])
          build_index if !index.root_exists?
          index.remove_record(record)
          index.save
          @results_cache = {}
          true
        end

        def search_index(query, find_options={}, options={})
          if !@results_cache || !@results_cache[query]
            logger.debug('Query not in cache, running search.')
            index = SearchIndex.new(aai_config[:index_file], aai_config[:index_file_depth], aai_config[:fields], aai_config[:min_word_size])
            build_index if !index.root_exists?
            index.save
            @results_cache = {} if !@results_cache
            @results_cache[query] = index.search(query)
          else
              logger.debug('Query held in cache.')
          end
          return @results_cache[query] if options.has_key?(:ids_only) && options[:ids_only]
          with_scope :find => find_options do
            # Doing the find like this eliminates the possibility of errors occuring
            # on either missing records (out-of-sync) or an empty results array.
            find(:all, :conditions => [ 'id IN (?)', @results_cache[query]])
          end
        end

        private

        def build_index
          index = SearchIndex.new(aai_config[:index_file], aai_config[:index_file_depth], aai_config[:fields], aai_config[:min_word_size])
          index.add_records(find(:all))
          index.save
        end

      end

      # Adds singleton methods.
      module SingletonMethods

        def find_with_index(query='', find_options = {}, options = {})
          search_index(query, find_options, options)
        end

      end

      # Adds instance methods.
      module InstanceMethods
        def add_to_index
          self.class.index_add(self)
        end

        def remove_from_index
          self.class.index_remove(self)
        end

        def update_index
          self.class.index_remove(self)
          self.class.index_add(self)
        end
      end

    end
  end
end

# reopen ActiveRecord and include all the above to make
# them available to all our models if they want it

ActiveRecord::Base.class_eval do
  include Foo::Acts::Indexed
end