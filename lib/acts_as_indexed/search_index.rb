# ActsAsIndexed
# Copyright (c) 2007 - 2010 Douglas F Shearer.
# http://douglasfshearer.com
# Distributed under the MIT license as included with this plugin.

module ActsAsIndexed #:nodoc:
  class SearchIndex

    # root:: Location of index on filesystem as a Pathname.
    # index_depth:: Degree of index partitioning.
    # fields:: Fields or instance methods of ActiveRecord model to be indexed.
    # min_word_size:: Smallest query term that will be run through search.
    # if_proc:: A Proc. If the proc is true, the index gets added, if false if doesn't
    def initialize(root, index_depth, fields, min_word_size, if_proc=Proc.new{true})
      @root = Pathname.new(root.to_s)
      @fields = fields
      @index_depth = index_depth
      @atoms = {}
      @min_word_size = min_word_size
      @records_size = exists? ? load_record_size : 0
      @if_proc = if_proc
    end

    # Adds +record+ to the index.
    def add_record(record, no_save=false)
      return unless @if_proc.call(record)
      condensed_record = condense_record(record)
      load_atoms(condensed_record)
      add_occurences(condensed_record,record.id)
      @records_size += 1
      self.save unless no_save
    end

    # Adds multiple records to the index. Accepts an array of +records+.
    def add_records(records)
      records.each do |record|
        add_record(record, true)
      end
      self.save
    end

    # Removes +record+ from the index.
    def remove_record(record)
      atoms = condense_record(record)
      load_atoms(atoms)
      atoms.each do |a|
        @atoms[a].remove_record(record.id) if @atoms.has_key?(a)
        @records_size -= 1
      end
      self.save
    end

    def update_record(record_new, record_old)
      remove_record(record_old)
      add_record(record_new)
    end

    # Saves the current index partitions to the filesystem.
    def save
      prepare
      atoms_sorted = {}
      @atoms.each do |atom_name, records|
        (atoms_sorted[encoded_prefix(atom_name)] ||= {})[atom_name] = records
      end
      atoms_sorted.each do |e_p, atoms|
        @root.join(e_p.to_s).open("w+") do |f|
          Marshal.dump(atoms,f)
        end
      end
      save_record_size
    end

    # Deletes the current model's index from the filesystem.
    #--
    # TODO: Write a public method that will delete all indexes.
    def destroy
      @root.delete
    end

    # Returns an array of IDs for records matching +query+.
    def search(query)
      return [] if query.nil?
      load_options = { :start => true } if query[/\^/]
      load_atoms(cleanup_atoms(query), load_options || {})
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
    
    # Returns true if the index root exists on the FS.
    #--
    # TODO: Make a private method called 'root_exists?' which checks for the root directory.
    def exists?
      @root.join('size').exist?
    end

    private

    # Gets the size file from the index.
    def load_record_size
      @root.join('size').open do |f|
        Marshal.load(f)
      end
    end

    # Saves the size to the size file.
    def save_record_size
      @root.join('size').open('w+') do |f|
        Marshal.dump(@records_size,f)
      end
    end

    # Returns true if the given atom is present.
    def include_atom?(atom)
      if atom.is_a? Regexp
        @atoms.keys.grep(atom).any?
      else
        @atoms.has_key?(atom)
      end
    end

    # Returns true if all the given atoms are present.
    def include_atoms?(atoms_arr)
      atoms_arr.each do |a|
        return false unless include_atom?(a)
      end
      true
    end

    # Returns true if the given record is present.
    def include_record?(record_id)
      @atoms.each do |atomname, atom|
        return true if atom.include_record?(record_id)
      end
    end

    def add_atom(atom)
      @atoms[atom] = SearchAtom.new unless include_atom?(atom)
    end

    def add_occurences(condensed_record,record_id)
      condensed_record.each_with_index do |atom, i|
        add_atom(atom)
        @atoms[atom].add_position(record_id, i)
      end
    end

    def encoded_prefix(atom)
      prefix = atom[0,@index_depth]
      unless (@prefix_cache ||= {}).has_key?(prefix)
        if atom.length > 1
          @prefix_cache[prefix] = prefix.split(//).map{|c| encode_character(c)}.join('_')
        else
          @prefix_cache[prefix] = encode_character(atom)
        end
      end
      @prefix_cache[prefix]
    end

    # Allows compatibility with 1.8.6 which has no ord method.
    def encode_character(char)
      if @@has_ord ||= char.respond_to?(:ord)
        char.ord.to_s
      else
        char[0]
      end
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
        :positive => positive }
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

    def load_atoms(atoms, options={})
      # Remove duplicate atoms.
      # Remove atoms already in index.
      # Calculate prefixes.
      # Remove duplicate prefixes.
      atoms.uniq.reject{|a| include_atom?(a)}.collect{|a| encoded_prefix(a)}.uniq.each do |name|
        pattern = @root.join(name.to_s).to_s
        pattern += '*' if options[:start]
        Pathname.glob(pattern).each do |atom_file|
          atom_file.open do |f|
            @atoms.merge!(Marshal.load(f))
          end
        end
      end
    end

    def prepare
      # Makes the RAILS_ROOT/index/ENVIRONMENT/CLASS directories
      @root.mkpath
    end

    def cleanup_atoms(s, limit_size=false, min_size = @min_word_size || 3)
      atoms = s.downcase.gsub(/\W/,' ').squeeze(' ').split
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
