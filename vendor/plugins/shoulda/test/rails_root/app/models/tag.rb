class Tag < ActiveRecord::Base
  has_many :taggings
  has_many :posts, :through => :taggings
  
  validates_length_of :name, :minimum => 2
end
