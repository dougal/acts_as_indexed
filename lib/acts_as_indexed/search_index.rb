module ActsAsIndexed #:nodoc:
  class SearchIndex

    # fields:: Fields or instance methods of ActiveRecord model to be indexed.
    # config:: ActsAsIndexed::Configuration instance.
    def initialize(fields, config)
      @storage = Storage.new(config)
      @fields = fields
      @atoms = ActiveSupport::OrderedHash.new
      @min_word_size = config.min_word_size
      @records_size = @storage.record_count
      @case_sensitive = config.case_sensitive
      @if_proc = config.if_proc
    end

    # Adds +record+ to the index.
    def add_record(record)
      return unless allow_indexing?(record)

      condensed_record = condense_record(record)
      atoms = add_occurences(condensed_record, record.id)

      @storage.add(atoms)
    end

    # Adds multiple records to the index. Accepts an array of +records+.
    def add_records(records)
      atoms = ActiveSupport::OrderedHash.new
      records_count = 0

      records.each do |record|
        next unless allow_indexing?(record)
        records_count += 1

        condensed_record = condense_record(record)
        atoms = add_occurences(condensed_record, record.id, atoms)
      end

      @storage.add(atoms, records_count)
    end

    # Removes +record+ from the index.
    def remove_record(record)
      condensed_record = condense_record(record)
      atoms = add_occurences(condensed_record,record.id)

      @storage.remove(atoms)
    end

    def update_record(record_new, record_old)
      if !record_unchanged?(record_new, record_old)
        remove_record(record_old)
        add_record(record_new)

      # Always try to remove the record if it is non-indexable, in case proc
      # makes use of any methods or attributes exteral of the record.
      elsif !allow_indexing?(record_new)
        remove_record(record_old)
      end
    end

    # Returns an array of IDs for records matching +query+.
    def search(query)
      return [] if query.nil?

      @atoms = @storage.fetch(cleanup_atoms(query), query[/\^/])
      queries = parse_query(query.dup)
      positive = run_queries(queries[:positive])
      positive_quoted = run_quoted_queries(queries[:positive_quoted])
      negative = run_queries(queries[:negative])
      negative_quoted = run_quoted_queries(queries[:negative_quoted])
      starts_with = run_queries(queries[:starts_with], true)
      start_quoted = run_quoted_queries(queries[:start_quoted], true)

      results = ActiveSupport::OrderedHash.new

      if queries[:start_quoted].any?
        results = merge_query_results(results, start_quoted)
      end

      if queries[:starts_with].any?
        results = merge_query_results(results, starts_with)
      end

      if queries[:positive_quoted].any?
        results = merge_query_results(results, positive_quoted)
      end

      if queries[:positive].any?
        results = merge_query_results(results, positive)
      end

      negative_results = (negative.keys + negative_quoted.keys)
      results.delete_if { |r_id, w| negative_results.include?(r_id) }
      results
    end

    private

    # The record is unchanged for our purposes if all the fields are the same
    # and the if_proc returns the same result for both.
    def record_unchanged?(record_new, record_old)
      # NOTE: Using the dirty state would be great here, but it doesn't keep track of
      # in-place changes.

      allow_indexing?(record_old) == allow_indexing?(record_new) &&
        !@fields.map { |field| record_old.send(field) == record_new.send(field) }.include?(false)
    end

    def allow_indexing?(record)
      @if_proc.call(record)
    end

    def merge_query_results(results1, results2)
      # Return the other if one is empty.
      return results1 if results2.empty?
      return results2 if results1.empty?

      # Delete any records from results 1 that are not in results 2.
      r1 = results1.delete_if{ |r_id,w| !results2.include?(r_id) }


      # Delete any records from results 2 that are not in results 1.
      r2 = results2.delete_if{ |r_id,w| !results1.include?(r_id) }

      # Merge the results by adding their respective scores.
      r1.merge(r2) { |r_id,old_val,new_val| old_val + new_val}
    end

    def add_occurences(condensed_record, record_id, atoms=ActiveSupport::OrderedHash.new)
      condensed_record.each_with_index do |atom_name, i|
        atoms[atom_name] = SearchAtom.new unless atoms.include?(atom_name)
        atoms[atom_name].add_position(record_id, i)
      end
      atoms
    end

    def parse_query(s)

      # Find ^"foo bar".
      start_quoted = []
      while st_quoted = s.slice!(/\^\"[^\"]*\"/)
        start_quoted << cleanup_atoms(st_quoted)
      end

      # Find -"foo bar".
      negative_quoted = []
      while neg_quoted = s.slice!(/-\"[^\"]*\"/)
        negative_quoted << cleanup_atoms(neg_quoted)
      end

      # Find "foo bar".
      positive_quoted = []
      while pos_quoted = s.slice!(/\"[^\"]*\"/)
        positive_quoted << cleanup_atoms(pos_quoted)
      end

      # Find ^foo.
      starts_with = []
      while st_with = s.slice!(/\^[\S]*/)
        starts_with << cleanup_atoms(st_with).first
      end

      # Find -foo.
      # Ignores instances where a dash is used as a hyphen.
      negative = []
      s.gsub!(/^(.*\s)?-(\S*)/) do |match|
        negative << cleanup_atoms($2).first

        $1
      end

      # Find +foo
      positive = []
      while pos = s.slice!(/\+[\S]*/)
        positive << cleanup_atoms(pos).first
      end

      # Find all other terms.
      positive += cleanup_atoms(s,true)

      { :start_quoted => start_quoted,
        :negative_quoted => negative_quoted,
        :positive_quoted => positive_quoted,
        :starts_with => starts_with,
        :negative => negative,
        :positive => positive
      }
    end

    def run_queries(atoms, starts_with=false)
      results = ActiveSupport::OrderedHash.new
      atoms.each do |atom|
        interim_results = ActiveSupport::OrderedHash.new

        # If these atoms are to be run as 'starts with', make them a Regexp
        # with a carat.
        atom = /^#{atom}/ if starts_with

        # Get the resulting matches, and break if none exist.
        matches = get_atom_results(@atoms.keys, atom)
        break if matches.nil?

        # Grab the record IDs and weightings.
        interim_results = matches.weightings(@records_size)

        # Merge them with the results obtained already, if any.
        results = results.empty? ? interim_results : merge_query_results(results, interim_results)

        break if results.empty?

      end
      results
    end

    def run_quoted_queries(quoted_atoms, starts_with=false)
      results = ActiveSupport::OrderedHash.new
      quoted_atoms.each do |quoted_atom|
        interim_results = ActiveSupport::OrderedHash.new

        break if quoted_atom.empty?

        # If these atoms are to be run as 'starts with', make the final atom a
        # Regexp with a line-start anchor.
        quoted_atom[-1] = /^#{quoted_atom.last}/ if starts_with

        # Little bit of memoization.
        atoms_keys = @atoms.keys

        # Get the matches for the first atom.
        matches = get_atom_results(atoms_keys, quoted_atom.first)
        break if matches.nil?

        # Check the index contains all the required atoms.
        # for each of the others
        #   return atom containing records + positions where current atom is preceded by following atom.
        # end
        # Return records from final atom.
        quoted_atom[1..-1].each do |atom_name|
          interim_matches = get_atom_results(atoms_keys, atom_name)
          if interim_matches.nil?
            matches = nil
            break
          end
          matches = interim_matches.preceded_by(matches)
        end

        break if matches.nil?
        # Grab the record IDs and weightings.
        interim_results = matches.weightings(@records_size)

        # Merge them with the results obtained already, if any.
        results = results.empty? ? interim_results : merge_query_results(results, interim_results)

        break if results.empty?

      end
      results
    end

    def get_atom_results(atoms_keys, atom)
      if atom.is_a? Regexp
        matching_keys = atoms_keys.grep(atom)
        results = SearchAtom.new
        matching_keys.each do |key|
          results += @atoms[key]
        end
        results
      else
        @atoms[atom]
      end
    end


    def cleanup_atoms(s, limit_size=false)
      pre_tokenized = PreTokenizer.process(s)
      tokenized     = Tokenizer.process(pre_tokenized)
      TokenNormalizer.process(tokenized, :normalize_case => !@case_sensitive, :min_token_length => !limit_size ? @min_token_length : false)
    end

    def condense_record(record)
      atoms = []

      @fields.each do |f|
        if (value = record.send(f)).present?
          atoms += cleanup_atoms(value.to_s)

          #U+3000 separates fields so that quoted terms cannot match across
          #fields
          atoms << "\u3000"
        end
      end

      atoms
    end

  end
end
