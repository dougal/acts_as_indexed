# ActsAsIndexed
# Copyright (c) 2007 Douglas F Shearer.
# http://douglasfshearer.com
# Distributed under the MIT license as included with this plugin.

module Foo #:nodoc:
  module Acts #:nodoc:
    module Indexed #:nodoc:
      class SearchIndex
        
        # root:: Location of index on filesystem.
        # index_depth:: Degree of index partitioning.
        # fields:: Fields or instance methods of ActiveRecord model to be indexed.
        # min_word_size:: Smallest query term that will be run through search.
        def initialize(root, index_depth, fields, min_word_size)
          @root = root
          @fields = fields
          @index_depth = index_depth
          @atoms = {}
          @min_word_size = min_word_size
        end

        # Adds +record+ to the index.
        def add_record(record)
          load_atoms(cleanup_atoms(condense_record(record,@fields)))
          add_occurences(record)
        end
        
        # Adds multiple records to the index. Accepts an array of +records+.
        def add_records(records)
          records.each do |r|
            add_occurences(r)
          end
        end

        # Removes +record+ from the index.
        def remove_record(record)
          atoms = cleanup_atoms(condense_record(record,@fields))
          load_atoms(atoms)
          atoms.each do |a|
            @atoms[a].remove_record(record.id)
          end
        end

        # Saves the current index partitions to the filesystem.
        def save
          prepare
          atoms_sorted = {}
          @atoms.each do |atom_name, records|
            e_p = encoded_prefix(atom_name)
            atoms_sorted[e_p] = {} if !atoms_sorted.has_key?(e_p)
            atoms_sorted[e_p][atom_name] = records
          end
          atoms_sorted.each do |e_p, atoms|
            #p "Saving #{e_p}."
            File.open(File.join(@root + [e_p.to_s]),'w+') do |f|
              Marshal.dump(atoms,f)
            end
          end
        end
        
        # Deletes the current model's index from the filesystem.
        #--
        # TODO: Write a public method that will delete all indexes.
        def destroy
          FileUtils.rm_rf(@root)
          true
        end

        # Returns an array of IDs for records matching +query+.
        def search(query)
          load_atoms(cleanup_atoms(query))
          return [] if query.nil?
          queries = parse_query(query.dup)
          positive = run_queries(queries[:positive])
          positive_quoted = run_quoted_queries(queries[:positive_quoted])
          negative = run_queries(queries[:negative])
          negative_quoted = run_quoted_queries(queries[:negative_quoted])
          results = (positive.empty? || positive_quoted.empty?) ? (positive + positive_quoted) : (positive & positive_quoted)
          results -= (negative + negative_quoted).uniq
        end

        # Returns true if the index root exists on the FS.
        #--
        # TODO: Make a private method called 'root_exists?' which checks for the root directory.
        def exists?
          File.exists?(File.join(@root))
        end

        private

        # Returns true if the given atom is present.
        def include_atom?(atom)
          @atoms.has_key?(atom)
        end

        # Returns true if the given record is present.
        def include_record?(record_id)
          @atoms.each do |atomname, atom|
            return true if atom.include_record?(record_id)
          end
        end

        def add_atom(atom)
          @atoms[atom] = SearchAtom.new if !include_atom?(atom)
        end

        def add_occurences(record)
          cleanup_atoms(condense_record(record,@fields)).each_with_index do |atom, i|
            add_atom(atom)
            @atoms[atom].add_position(record.id, i)
          end
        end

        def encoded_prefix(atom)
          prefix = atom[0,@index_depth]
          if !@prefix_cache || !@prefix_cache.has_key?(prefix)
            @prefix_cache = {} if !@prefix_cache
            len = atom.length
            if len > 1
              @prefix_cache[prefix] = prefix.split(//).collect{|c| c[0]}.inject{|sum,c| sum.to_s + '_' + c.to_s}
            else
              @prefix_cache[prefix] = atom[0].to_s
            end
          end
          @prefix_cache[prefix]
        end

        def parse_query(s)

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

          return {:negative_quoted => negative_quoted, :positive_quoted => positive_quoted, :negative => negative, :positive => positive}
        end

        def run_queries(atoms)
          results = []
          atoms.uniq.each do |atom|
            if include_atom?(atom)
              if results.empty?
                results = @atoms[atom].record_ids
              else
                results = results & @atoms[atom].record_ids
              end
            end
          end
          results
        end

        def run_quoted_queries(arr)
          results = []
          arr.each do |phrase|
            matches = nil
            phrase.each do |word|
              new_matches = {}
              current = @atoms[word]
              if current.nil?
                matches = {}
              else
                current = current.to_h
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

        def load_atoms(atoms)
          # Remove duplicates
          # Remove atoms already in index.
          # Calculate prefixes.
          # Remove duplicates
          atoms.uniq.reject{|a| include_atom?(a)}.collect{|a| encoded_prefix(a)}.uniq.each do |name|
            if File.exists?(File.join(@root + [name.to_s]))
              File.open(File.join(@root + [name.to_s])) do |f|
                @atoms.merge!(Marshal.load(f))
              end
            end
          end
        end

        def prepare
          # Makes the RAILS_ROOT/index directory
          Dir.mkdir(File.join(@root[0,2])) if !File.exists?(File.join(@root[0,2]))
          # Makes the RAILS_ROOT/index/ENVIRONMENT directory
          Dir.mkdir(File.join(@root[0,3])) if !File.exists?(File.join(@root[0,3]))
          # Makes the RAILS_ROOT/index/ENVIRONMENT/CLASS directory
          Dir.mkdir(File.join(@root)) if !File.exists?(File.join(@root))
        end

        def cleanup_atoms(s, limit_size=false, min_size = @min_word_size || 3)
          atoms = s.downcase.gsub(/\W/,' ').squeeze(' ').split
          return atoms if !limit_size
          atoms.reject{|w| w.size < min_size}
        end

        def condense_record(record, fields)
          record_condensed = ''
          fields.each do |f|
            record_condensed += ' ' + record.send(f).to_s if record.send(f)
          end
          record_condensed
        end

      end
    end
  end
end