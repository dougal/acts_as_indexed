# ActsAsIndexed
# Copyright (c) 2007 - 2011 Douglas F Shearer.
# http://douglasfshearer.com
# Distributed under the MIT license as included with this plugin.

module ActsAsIndexed #:nodoc:
  class SearchIndex

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
      queries = parse_query(query.dup)
      positive = run_queries(queries[:positive])
      positive_quoted = run_quoted_queries(queries[:positive_quoted])
      negative = run_queries(queries[:negative])
      negative_quoted = run_quoted_queries(queries[:negative_quoted])
      starts_with = run_queries(queries[:starts_with], true)
      start_quoted = run_quoted_queries(queries[:start_quoted], true)

      results = {}

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

    def add_occurences(condensed_record, record_id, atoms={})
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
      negative = []
      while neg = s.slice!(/-[\S]*/)
        negative << cleanup_atoms(neg).first
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
      results = {}
      atoms.each do |atom|
        interim_results = {}

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
      results = {}
      quoted_atoms.each do |quoted_atom|
        interim_results = {}

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
