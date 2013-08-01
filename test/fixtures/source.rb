class Source < ActiveRecord::Base
  acts_as_indexed :fields => [:name, :description]
end