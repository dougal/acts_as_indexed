# ActsAsIndexed
# Copyright (c) 2007 - 2010 Douglas F Shearer.
# http://douglasfshearer.com
# Distributed under the MIT license as included with this plugin.

module ActsAsIndexed #:nodoc:
  class Storage

    def initialize(path, prefix_size)
      @path = path
      @prefix_size = prefix_size
      prepare
    end

    # Takes a hash of atoms and adds these to storage.
    def add(atoms)
      operate(:+, atoms)

      update_record_count(1)

    end

    # Takes a hash of atoms and removes these from storage.
    def remove(atoms)
      operate(:-, atoms)

      update_record_count(-1)
    end

    # Takes a string array of atoms names
    # return a hash of the relevant atoms.
    def fetch(atom_names, start=false)
      atoms = {}

      atom_names.uniq.collect{|a| encoded_prefix(a) }.uniq.each do |prefix|
        pattern = @path.join(prefix.to_s).to_s
        pattern += '*' if start

        Pathname.glob(pattern).each do |atom_file|
          atom_file.open do |f|
            atoms.merge!(Marshal.load(f))
          end
        end # Pathname.glob

      end # atom_names.uniq
      atoms
    end # fetch.

    # Returns the number of records currently stored in this index.
    def record_count
      # TODO: Record count is currently a marshaled integer. Why not store as
      # string integer? Breaks compatibility, so leave until other changes
      # need to be made to the index.
      
      @path.join('size').open do |f|
        Marshal.load(f)
      end
      
    # This is a bit horrible.
    rescue Errno::ENOENT
      0
    rescue EOFError
      0
    end

    private

    # Takes atoms and adds or removes them from the index depending on the
    # passed operation.
    def operate(operation, atoms)
      # ActiveSupport always available?
      atoms_sorted = ActiveSupport::OrderedHash.new

      # Sort the atoms into the appropriate shards for writing to individual
      # files.
      atoms.each do |atom_name, records|
        (atoms_sorted[encoded_prefix(atom_name)] ||= {})[atom_name] = records
      end

      atoms_sorted.each do |e_p, atoms|
        path = @path.join(e_p.to_s)

        if path.exist?
          from_file = path.open do |f|
            Marshal.load(f)
          end
        else
          from_file = {}
        end

        atoms = from_file.merge(atoms){ |k,o,n| o.send(operation, n) }

        path.open("w+") do |f|
          Marshal.dump(atoms,f)
        end
      end
    end

    def update_record_count(delta)
      new_count = self.record_count + delta
      new_count = 0 if new_count < 0
      
      @path.join('size').open('w+') do |f|
        Marshal.dump(new_count,f)
      end
    end

    def prepare
      @path.mkpath unless @path.exist?
    end

    def encoded_prefix(atom)
      prefix = atom[0, @prefix_size]

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

  end
end