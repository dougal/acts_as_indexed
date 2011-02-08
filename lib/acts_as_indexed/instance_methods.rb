# ActsAsIndexed
# Copyright (c) 2007 - 2011 Douglas F Shearer.
# http://douglasfshearer.com
# Distributed under the MIT license as included with this plugin.

module ActsAsIndexed
  
  # Adds model class instance methods.
  # Methods are called automatically by ActiveRecord on +save+, +destroy+,
  # and +update+ of model instances.
  module InstanceMethods

    # Adds the current model instance to index.
    # Called by ActiveRecord on +save+.
    def add_to_index
      self.class.index_add(self)
    end

    # Removes the current model instance to index.
    # Called by ActiveRecord on +destroy+.
    def remove_from_index
      self.class.index_remove(self)
    end

    # Updates current model instance index.
    # Called by ActiveRecord on +update+.
    def update_index
      self.class.index_update(self)
    end
  end
  
end
