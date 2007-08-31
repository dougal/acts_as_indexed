require 'active_record'
require 'class_methods'
require 'instance_methods'
require 'singleton_methods'

module Foo
  module Acts #:nodoc:
    module Indexed #:nodoc:

      def self.included(mod)
        mod.extend(ClassMethods)
      end

    end
  end
end

# reopen ActiveRecord and include all the above to make
# them available to all our models if they want it

ActiveRecord::Base.class_eval do
  include Foo::Acts::Indexed
end