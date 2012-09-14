# ActsAsIndexed
# Copyright (c) 2007 - 2011 Douglas F Shearer.
# http://douglasfshearer.com
# Distributed under the MIT license as included with this plugin.

module ActsAsIndexed #:nodoc:
  class SearchIndex
    attr_reader :atoms, :records_size, :default_operator
    
    @@expressions_attributes = [
      [/\^\"[^\"]*\"/, {:sign => :neutral,  :quoted => true,  :start => true} ], # Find ^"foo bar".
      [/-\"[^\"]*\"/,  {:sign => :negative, :quoted => true,  :start => false}], # Find -"foo bar".
      [/\"[^\"]*\"/,   {:sign => :neutral,  :quoted => true,  :start => false}], # Find "foo bar".
      [/\^[\S]*/,      {:sign => :neutral,  :quoted => false, :start => true} ], # Find ^foo.
      [/-[\S]*/,       {:sign => :negative, :quoted => false, :start => false}], # Find -foo.
      [/\+[\S]*/,      {:sign => :positive, :quoted => false, :start => false}]  # Find +foo
    ]

    # fields:: Fields or instance methods of ActiveRecord model to be indexed.
    # config:: ActsAsIndexed::Configuration instance.
    def initialize(fields, config)
      @storage = Storage.new(Pathname.new(config.index_file.to_s), config.index_file_depth)
      @fields = fields
      @atoms = {}
      @min_word_size = config.min_word_size
      @records_size = @storage.record_count
      @case_sensitive = config.case_sensitive
      @if_proc = config.if_proc
      @default_operator = config.default_operator
    end

    # Adds +record+ to the index.
    def add_record(record)
      return unless @if_proc.call(record)

      condensed_record = condense_record(record)
      atoms = add_occurences(condensed_record, record.id)

      @storage.add(atoms)
    end

    # Adds multiple records to the index. Accepts an array of +records+.
    def add_records(records)
      atoms = {}

      records.each do |record|
        next unless @if_proc.call(record)

        condensed_record = condense_record(record)
        atoms = add_occurences(condensed_record, record.id, atoms)
      end

      @storage.add(atoms)
    end

    # Removes +record+ from the index.
    def remove_record(record)
      condensed_record = condense_record(record)
      atoms = add_occurences(condensed_record,record.id)

      @storage.remove(atoms)
    end

    def update_record(record_new, record_old)
      remove_record(record_old)
      add_record(record_new)
    end

    # Returns an array of IDs for records matching +query+.
    def search(query)
      return [] if query.nil?

      @atoms = @storage.fetch(cleanup_atoms(query), query[/\^/])

      # Parses the queries
      queries = parse_query(query.dup)
      
      # updates the sign of the queries based on the default operator setting
      queries.each {|query| query.sign = :positive if query.sign == :neutral} if @default_operator == :and
      
      # run the queries and merge their results
      Query.merge(queries.each {|query| query.run})
    end
    
    # Query objects encapsulates all the details of query terms, so that
    # running the results is homogenous and merging the results is deterministic
    class Query
      attr_reader :quoted, :start, :results
      attr_accessor :sign
      
      # atom_names: array of words
      # options:
      #   :sign     :positive, :negative, :neutral
      #   :quoted   true/false
      #   :start    true/false
      def initialize(atom_names, search_index, options={})
        @search_index = search_index
        @atom_names = atom_names
        @sign = options[:sign]
        @quoted = options[:quoted]
        @start = options[:start]
      end
      
      def run
        # little memoization
        @atoms = @search_index.atoms
        @atoms_keys = @atoms.keys
        @records_size = @search_index.records_size
        @intersect_merge = @search_index.default_operator == :and || @sign == :positive
        
        @results = @quoted ? run_quoted_queries(@atom_names, @start) : run_queries(@atom_names, @start)
      end
      
      class << self
        # how do we merge the queries?
        # First of all, the order of the words in the query string should not be relevent,
        # so only the kind of query is.
        # Examples with the default operator (for neutral words) to :and
        #   dog cat +bird -eagle -falcon
        #   means: all documents containing dog AND cat AND bird AND NOT eagle AND NOT falcon.
        #   A document containing dog cat bird eagle will thus match because it lacks falcon.
        #
        #   The resulting algorithm is: merging (legacy aai way, which is keeping only the intersect)
        #   all the neutral and positive results, then removing the negative ones.
        #
        # Examples with the default operator (for neutral words) to :or
        #   dog cat +bird -eagle -falcon
        #   means: all documents containing at least bird with documents that may contain dog OR cat but without eagle OR falcon.
        #   A document containing dog cat will not match because it lacks bird.
        #   A document containing bird eagle will not match because it contains eagle.
        #   A document containing bird will match, if the same document contains also cat or dog it has a better relevance.
        #
        #   The resulting algorithm is: merging (legacy aai way, which is keeping only the intersect)
        #   all the positive results, then adding all the neutral result and then removing the negative ones.
        def merge(queries)
          groups = queries.group_by {|query| query.sign}
          
          positives = (groups[:positive] || []).inject([]) {|memo, query| intersect_results(memo, query.results) }
          neutrals  = (groups[:neutral]  || []).inject([]) {|memo, query| add_results(memo, query.results) }
          
          # combining positives and neutral is by keeping only the positives but adding the weight of atoms that are also present in neutrals.
          results = augment_results(positives, neutrals)
          
          (groups[:negative] || []).each {|query| results = remove_results(results, query.results) }
          results
        end
        
        def intersect_results(results1, results2)
          # Return the other if one is empty.
          return results1 if results2.empty?
          return results2 if results1.empty?

          # Delete any records from results 1 that are not in results 2.
          r1 = results1.reject{ |r_id,w| !results2.include?(r_id) }

          # Delete any records from results 2 that are not in results 1.
          r2 = results2.reject{ |r_id,w| !results1.include?(r_id) }

          # Merge the results by adding their respective scores.
          r1.merge(r2) { |r_id,old_val,new_val| old_val + new_val}
        end

        def add_results(results1, results2)
          # Return the other if one is empty.
          return results1 if results2.empty?
          return results2 if results1.empty?

          # Merge the results by adding their respective scores.
          results1.merge(results2) { |r_id,old_val,new_val| old_val + new_val}
        end

        def remove_results(results, results_to_remove)
          keys_to_remove = results_to_remove.keys
          results.delete_if { |r_id, w| keys_to_remove.include?(r_id) }
        end
        
        def augment_results(results1, results2)
          # Return the other if one is empty.
          return results1 if results2.empty?
          return results2 if results1.empty?
          
          results1.each do |r_id,w|
            if weight_to_add = results2[r_id]
              results1[r_id] += weight_to_add
            end
          end
        end
      end
      
      protected

      def merge_query_results(results1, results2)
        @intersect_merge ? self.class.intersect_results(results1, results2) : self.class.add_results(results1, results2)
      end

      def run_queries(atoms, starts_with=false)
        results = {}
        atoms.each do |atom|
          interim_results = {}

          # If these atoms are to be run as 'starts with', make them a Regexp
          # with a carat.
          atom = /^#{atom}/ if starts_with

          # Get the resulting matches, and break if none exist.
          matches = get_atom_results(atom)
          next if matches.nil?

          # Grab the record IDs and weightings.
          interim_results = matches.weightings(@records_size)

          # Merge them with the results obtained already.
          results = merge_query_results(results, interim_results)
        end
        results
      end

      def run_quoted_queries(quoted_atoms, starts_with=false)
        results = {}
        quoted_atoms.each do |quoted_atom|
          interim_results = {}

          next if quoted_atom.empty?

          # If these atoms are to be run as 'starts with', make the final atom a
          # Regexp with a line-start anchor.
          quoted_atom[-1] = /^#{quoted_atom.last}/ if starts_with

          # Get the matches for the first atom.
          matches = get_atom_results(quoted_atom.first)
          next if matches.nil?

          # Check the index contains all the required atoms.
          # for each of the others
          #   return atom containing records + positions where current atom is preceded by following atom.
          # end
          # Return records from final atom.
          quoted_atom[1..-1].each do |atom_name|
            interim_matches = get_atom_results(atom_name)
            if interim_matches.nil?
              matches = nil
              break
            end
            matches = interim_matches.preceded_by(matches)
          end
          next if matches.nil?
          
          # Grab the record IDs and weightings.
          interim_results = matches.weightings(@records_size)

          # Merge them with the results obtained already.
          results = merge_query_results(results, interim_results)
        end
        results
      end

      def get_atom_results(atom)
        if atom.is_a? Regexp
          matching_keys = @atoms_keys.grep(atom)
          results = SearchAtom.new
          matching_keys.each do |key|
            results += @atoms[key]
          end
          results
        else
          @atoms[atom]
        end
      end
      
    end

    private

    def add_occurences(condensed_record, record_id, atoms={})
      condensed_record.each_with_index do |atom_name, i|
        atoms[atom_name] = SearchAtom.new unless atoms.include?(atom_name)
        atoms[atom_name].add_position(record_id, i)
      end
      atoms
    end

    def parse_query(s)
      # Find all expressions in the query
      queries = @@expressions_attributes.collect do |(regexp, attributes)|
        words = []
        while word = s.slice!(regexp)
          words << cleanup_atoms(word)
        end
        words.flatten! unless attributes[:quoted]
        Query.new(words, self, attributes)
      end

      # Find all other terms.
      words = cleanup_atoms(s,true)
      queries << Query.new(words, self, :sign => :neutral, :quoted => false, :start => false)
    end

    def cleanup_atoms(s, limit_size=false, min_size = @min_word_size || 3)
      s = @case_sensitive ? s : s.downcase
      atoms = s.gsub(/\W/,' ').squeeze(' ').split
      return atoms unless limit_size
      atoms.reject{|w| w.size < min_size}
    end

    def condense_record(record)
      condensed = []
      @fields.each do |f|
        if (value = record.send(f)).present?
          condensed << value.to_s
        end
      end
      cleanup_atoms(condensed.join(' '))
    end

  end
end
