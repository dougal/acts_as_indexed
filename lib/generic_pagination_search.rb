# GenericSearch
# Copyright (c) 2011 Philip Arndt.

module ActsAsIndexed
   module GenericPagination
     module Search

      def paginate_search(query, options)
        page = options[:page] || 1
        per_page = options[:per_page] || self.per_page
        total_entries = options[:total_entries] || find_with_index(query,{},{:ids_only => true}).size

        options = options.merge(:offset => ((page - 1) * per_page), :limit => per_page).
                          except(:page, :per_page)

        find_with_index(query, options)
      end

    end
  end
end

class ActiveRecord::Base
  extend ActsAsIndexed::GenericPagination::Search
end
