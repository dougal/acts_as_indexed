class Source < ActiveRecord::Base
  acts_as_indexed :fields => [:name, :description]
  
  validates_presence_of :name, :description, :url
end
