# ActsAsIndexed
# Copyright (c) 2007 Douglas F Shearer.
# http://douglasfshearer.com
# Distributed under the MIT license as included with this plugin.

module Foo #:nodoc:
  module Acts #:nodoc:
    module Indexed #:nodoc:
      class SearchAtom

        # Contains a hash of records.
        # { 'record_id' => [pos1, pos2, pos] }

        def initialize
          @records = {}
        end
        
        # Returns true if the given record is present.
        def include_record?(record_id)
          @records.include?(record_id)
        end

        # Adds +record_id+ to the stored records.
        def add_record(record_id)
          @records[record_id] = [] if !include_record?(record_id)
        end

        # Adds +pos+ to the array of positions for +record_id+.
        def add_position(record_id, pos)
          add_record(record_id)
          @records[record_id] << pos
        end
        
        # Returns all record IDs stored in this Atom.
        def record_ids
          @records.keys
        end

        # Returns an array of positions for +record_id+ stored in this Atom.
        def positions(record_id)
          return @records[records] if include_record?(record_id)
          nil
        end

        # Converts Atom to a hash of form:
        #  { record_id => [ pos1, po2, pos3 ] }
        def to_h
          @records
        end
        
        # Removes +record_id+ from this Atom.
        def remove_record(record_id)
          @records.delete(record_id)
        end

      end
    end
  end
end