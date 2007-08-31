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
            :min_word_size => 3,
            :fields => []
          }

          # set fields
          aai_config[:fields] = options[:fields] if options.include?(:fields)
          
          # set minimum word size if available.
          aai_config[:min_word_size] = options[:min_word_size] if options.include?(:min_word_size)
          
          # Set file location for plugin testing.
          # TODO: Find more portable (ruby) way of doing the up-one-level.
          aai_config[:index_file] = [File.dirname(__FILE__),'../test/index',RAILS_ENV,name] if options.include?(:self_test)
          
        end

        def index_add(record)
          index = load_index
          index = add_to_index(record, index)
          save_index(index)
        end

        def index_remove(record_id)
          index = load_index
          index.each do |k,v|
            v.delete(record_id)
          end
          save_index(index)
        end

        def search_index(query, ids=false)
          index = load_index
          return [] if query.nil?
          queries = parse_query(query)
          positive = run_queries(queries[:positive],index)
          positive_quoted = run_quoted_queries(queries[:positive_quoted],index)
          negative = run_queries(queries[:negative],index)
          negative_quoted = run_quoted_queries(queries[:negative_quoted],index)
          results = (positive.empty? || positive_quoted.empty?) ? (positive + positive_quoted) : (positive & positive_quoted)
          results -= (negative + negative_quoted).uniq
          
          return results if ids
          # Doing the find like this eliminates the possibility of errors occuring
          # on either missing records (out-of-sync) or an empty results array.
          find(:all, :conditions => [ 'id IN (?)', results])
        end

        protected
        
        def add_to_index(record, index)
          record_condensed = ''
          aai_config[:fields].each do |f|
            record_condensed += ' ' + record.send(f).to_s if record.send(f)
          end
          cleanup(record_condensed).each_with_index do |word,i|
            index[word] = {} if !index.has_key?(word)
            index[word][record.id] = [] if !index[word].has_key?(record.id)
            index[word][record.id] << i
          end
          index
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

        def load_index
          build_index if !index_exists?
          File.open(File.join(aai_config[:index_file])) do |f|
            Marshal.load(f)
          end
        end

        def save_index(index)
          File.open(File.join(aai_config[:index_file]),'w+') do |f|
            Marshal.dump(index,f)
          end
          true
        end

        def destroy_index

        end

        def index_exists?
          File.exists?(File.join(aai_config[:index_file]))
        end

        def build_index
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
        end

        def cleanup(s)
          s.downcase.gsub(/\W/,' ').squeeze(' ').split.reject{|w| w.size < aai_config[:min_word_size]}
        end

      end

      # Adds singleton methods.
      module SingletonMethods
        def find_with_index(query='',ids=false)
            search_index(query,ids)
        end
      end

      # Adds instance methods.
      module InstanceMethods
        def add_to_index
          self.class.index_add(self)
        end

        def remove_from_index
          self.class.index_remove(self.id)
        end

        def update_index
          self.class.index_remove(self.id)
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