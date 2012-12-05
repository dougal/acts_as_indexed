module ActsAsIndexed

   module WillPaginate

     module Search

      def paginate_search(query, options)
        page = options.fetch(:page) { raise ArgumentError, ":page parameter required" }
        per_page = options.delete(:per_page) || self.per_page
        total_entries = options.delete(:total_entries)

        total_entries ||= find_with_index(query,{},{:ids_only => true}).size

        pager = ::WillPaginate::Collection.new(page, per_page, total_entries)
        options.update :offset => pager.offset, :limit => pager.per_page

        options = options.delete_if {|key, value| [:page, :per_page].include?(key) }

        pager.replace find_with_index(query, options)
        pager
      end

    end
  end
end

class ActiveRecord::Base
  extend ActsAsIndexed::WillPaginate::Search
end
