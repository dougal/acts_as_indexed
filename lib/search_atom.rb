# ActsAsIndexed
# Copyright (c) 2007 Douglas F Shearer.
# http://douglasfshearer.com
# Distributed under the MIT license as included with this plugin.

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
  
  def add_record(record_id)
    @records[record_id] = [] if !include_record?(record_id)
  end

  def add_position(record_id, pos)
    add_record(record_id)
    @records[record_id] << pos
  end
  
  def record_ids
    @records.keys
  end
  
  def positions(record_id)
    return @records[records] if include_record?(record_id)
    nil
  end
  
  def to_h
    @records
  end
  
  def remove_record(record_id)
    @records.delete(record_id)
  end

end