module Foo
  module Acts #:nodoc:
    module Indexed #:nodoc:

      # Adds singleton methods.
      module SingletonMethods

        def find_with_index(query='',ids=false)
          search_index(query,ids)
        end

      end

    end
  end
end