# ActsAsIndexed
# Copyright (c) 2007 - 2011 Douglas F Shearer.
# http://douglasfshearer.com
# Distributed under the MIT license as included with this plugin.

module ActsAsIndexed #:nodoc:
  class SearchAtom

    # Contains a hash keyed by words having a commmon stem
    # each value is another hash from record ids to word numbers
    # { 'foo' => {record_id => [pos1, pos2, ...], }
    #   'fooing' => {record_id => [pos3, pos4, ...] }
    # }
    #--
    # Weighting:
    # http://www.perlmonks.com/index.pl?node_id=27509
    # W(T, D) = tf(T, D) * log ( DN / df(T))
    # weighting = frequency_in_this_record * log (total_number_of_records / number_of_matching_records)

    attr_reader :records

    def initialize(records={})
      @records = records
    end

    # Returns true if the given record is present.
    def include_record?(record_id)
      @records.values.any? {|record| record.member?(record_id)}
    end

    def include_token?(token)
      return @records.member? token
    end

    # Adds +token+ to the stored tokens.
    def add_token(token)
      @records[token] = {} unless @records[token]
    end

    def add_record_token(token, record_id)
      add_token(token)
      @records[token][record_id] ||= []
    end

    # Adds +pos+ to the array of positions for +token+ and +record_id+.
    def add_position(record_id, token, pos)
      add_record_token(token, record_id)
      @records[token][record_id] << pos
    end

    # This returns record->[positions], where positions is
    # all the positions across all tokens
    def flat_records
      flat = {}
      @records.each do |token, records|
        records.each do |record, positions|
          flat[record] ||= []
          flat[record] += positions
        end
      end
      flat
    end

    # Returns all record IDs stored in this Atom.
    def record_ids
      @records.values.map{|h| h.keys}.inject '+'
    end

    # Returns an array of positions for +record_id+ stored in this Atom.
    def all_positions(record_id)
      @records.values.map {|h| h[record_id]}.inject '+'
    end

    # Returns an hash of record->array of positions for +token+ stored
    # in this Atom.
    def records_by_token(token)
      @records[token]
    end

    # Removes +record_id+ from this Atom.
    def remove_record(record_id)
      @records.values.each{|v| v.delete(record_id)}
    end

    # Creates a new SearchAtom with the combined records from self and other
    def +(other)
      SearchAtom.new(@records.clone.merge!(other.records) {
                       |key, _old, _new|
                       _old.merge(_new) {
                         |k, o, n|
                         o + n
                       }
                     })
    end

    def exact(token)
      SearchAtom.new(Hash[*@records.find_all {|k, v| k == token }.flatten])
    end


    # Creates a new SearchAtom with records in other removed from self.
    def -(other)
      records = {}
      @records.each { |token, records_for_token|
        if other.records.include? (token)
          other_token_records = other.records[token]
          new_records = records_for_token.reject {|id, records| other_token_records.include?(id) }
          if new_records.size
            records[token] = new_records
          end
        end
      }
      SearchAtom.new(records)
    end

    # Returns an atom containing the records and positions of +self+
    # preceded by +former+ "former latter" or "big dog" where "big" is
    # the former and "dog" is the latter.

    def preceded_by(former)
      matches = SearchAtom.new

      for former_token, former_records in former.records
        for latter_token, latter_records in @records
          for latter_record, latter_positions in latter_records
            next unless former_records.member? latter_record

            #this record appears in both
            for former_pos in former_records[latter_record]
              if latter_positions.member? former_pos + 1
                matches.add_position(latter_record, latter_token, former_pos + 1)
              end
            end
          end
        end
      end
      matches
    end

    # Returns a hash of record_ids and weightings for each record in the
    # atom.
    def weightings(records_size)
      out = {}
      flat = flat_records
      flat.each do |r_id, pos|

        # Fixes a bug when the records_size is zero. i.e. The only record
        # contaning the word has been deleted.
        if records_size < 1
          out[r_id] = 0.0
          next
        end

        # weighting = frequency * log (records.size / records_with_atom)
        ## parndt 2010/05/03 changed to records_size.to_f to avoid -Infinity Errno::ERANGE exceptions
        ## which would happen for example Math.log(1 / 20) == -Infinity but Math.log(1.0 / 20) == -2.99573227355399
        out[r_id] = pos.size * Math.log(records_size.to_f / flat_records.size)
      end
      out
    end

    protected

    def include_position?(record_id,pos)
      @records.any? {|record|
        if record.include? record_id
          record[record_id].include?(pos)
        end
      }
    end

  end
end
