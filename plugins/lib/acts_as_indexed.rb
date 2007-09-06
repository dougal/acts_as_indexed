require 'active_record'

module Foo
  module Acts #:nodoc:
    module Indexed #:nodoc:

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
          index = load_index(cleanup(condense_record(record)))
          index = add_to_index(record, index)
          save_index(index)
        end

        def index_remove(record)
          index = load_index(cleanup(condense_record(record)))
          index.each do |k,v|
            v.delete(record.id)
          end
          save_index(index)
        end

        def search_index(query, find_options={}, options={})
          logger.debug('Starting search...')
          if !@results_cache || !@results_cache[query]
            logger.debug('Search does not exist in cache.')
            index = load_index(cleanup(query))
            return [] if query.nil?
            queries = parse_query(query)
            positive = run_queries(queries[:positive],index)
            positive_quoted = run_quoted_queries(queries[:positive_quoted],index)
            negative = run_queries(queries[:negative],index)
            negative_quoted = run_quoted_queries(queries[:negative_quoted],index)
            results = (positive.empty? || positive_quoted.empty?) ? (positive + positive_quoted) : (positive & positive_quoted)
            results -= (negative + negative_quoted).uniq
            @results_cache = {} if !@results_cache
            @results_cache[query] = results
          else
              logger.debug('Search exists in cache.')
          end

          return @results_cache[query] if options.has_key?(:ids_only) && options[:ids_only]
          with_scope :find => find_options do
            # Doing the find like this eliminates the possibility of errors occuring
            # on either missing records (out-of-sync) or an empty results array.
            find(:all, :conditions => [ 'id IN (?)', @results_cache[query]])
          end
        end

        def go_build_index
          build_index
        end

        protected

        def add_to_index(record, index)
          cleanup(condense_record(record)).each_with_index do |word,i|
            index[word] = {} if !index.has_key?(word)
            index[word][record.id] = [] if !index[word].has_key?(record.id)
            index[word][record.id] << i
          end
          index
        end

        def condense_record(record)
          record_condensed = ''
          aai_config[:fields].each do |f|
            record_condensed += ' ' + record.send(f).to_s if record.send(f)
          end
          record_condensed
        end

        def run_queries(arr,index)
          results = []
          arr.each do |word|
            if index.has_key?(word)
              if results.empty?
                results = index[word].keys
              else
                results = results & index[word].keys
              end
            end
          end
          return results
        end

        def run_quoted_queries(arr,index)
          results = []
          arr.each do |phrase|
            matches = nil
            phrase.each do |word|
              new_matches = {}
              current = index[word]
              if current.nil?
                matches = {}
              else
                if !matches
                  matches = current
                else
                  matches.each do |record_id, record_pos|
                    if current.include?(record_id)
                      record_pos.each do |pos|
                        if current[record_id].include?(pos+1)
                          new_matches[record_id] = current[record_id]
                          break
                        end
                      end
                    end
                  end
                  matches = new_matches
                end
              end
            end
            results = results + matches.keys
          end
          return results
        end

        def parse_query(s)

          # Find -"foo bar".
          negative_quoted = []
          while neg_quoted = s.slice!(/-\"[^\"]*\"/)
            negative_quoted << cleanup(neg_quoted)
          end

          # Find "foo bar".
          positive_quoted = []
          while pos_quoted = s.slice!(/\"[^\"]*\"/)
            positive_quoted << cleanup(pos_quoted)
          end

          # Find -foo.
          negative = []
          while neg = s.slice!(/-[\S]*/)
            negative << cleanup(neg).first
          end

          # Find all other terms.
          positive = cleanup(s)

          return {:negative_quoted => negative_quoted, :positive_quoted => positive_quoted, :negative => negative, :positive => positive}
        end

        def load_index(words = nil)
          logger.debug('Loading index...')
          build_index if !index_exists?

          getwhat = []
          if words
            words.each do |w|
              getwhat << word_prefix(w) if File.exists?(File.join(aai_config[:index_file] + [word_prefix(w)]))
            end
          else
            Dir.new(File.join(aai_config[:index_file])).each do |name|
              getwhat << name
            end
          end

          index = {}
          getwhat.each do |name|
            if name != '.' && name != '..'
              logger.debug("Loading index #{name}")
              File.open(File.join(aai_config[:index_file] + [name])) do |f|
                index.merge!(Marshal.load(f))
              end
            end
          end
          index
        end

        def save_index(index)
          logger.debug('Saving indexes')
          indexes = {}
          prefixes = {}
          index.each do |word,v|
            prefix = word[0,aai_config[:index_file_depth]]
            prefixes[prefix] ||= word_prefix(word)
            indexes[prefixes[prefix]] = {} if !indexes.has_key?(prefixes[prefix])
            indexes[prefixes[prefix]][word] = v
          end
          logger.debug("Number of indexes to save: #{indexes.size}")
          indexes.each do |prefix,v|
            logger.debug("Saving index #{prefix}")
            File.open(File.join(aai_config[:index_file] + [prefix.to_s]),'w+') do |f|
              Marshal.dump(v,f)
            end
          end
          true
        end

        def destroy_index

        end

        def index_exists?
          File.exists?(File.join(aai_config[:index_file]))
        end

        def build_index
          logger.debug('Building index from scratch...')
          prepare
          index = {}
          find(:all).each do |record|
            index = add_to_index(record, index)
          end
          save_index(index)
        end

        def prepare
          Dir.mkdir(File.join(aai_config[:index_file][0,2])) if !File.exists?(File.join(aai_config[:index_file][0,2]))
          Dir.mkdir(File.join(aai_config[:index_file][0,3])) if !File.exists?(File.join(aai_config[:index_file][0,3]))
          Dir.mkdir(File.join(aai_config[:index_file])) if !File.exists?(File.join(aai_config[:index_file]))
        end

        def word_prefix(word)
          len = word.length
          if len > 1
            word[0,aai_config[:index_file_depth]].split(//).collect{|c| c[0]}.inject{|sum,c| sum.to_s + '_' + c.to_s}
          else
            word.slice(0,1)[0].to_s
            logger.debug 'here'
          end
        end

        def cleanup(s)
          s.downcase.gsub(/\W/,' ').squeeze(' ').split.reject{|w| w.size < aai_config[:min_word_size]}
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