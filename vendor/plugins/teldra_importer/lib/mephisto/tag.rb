module Mephisto
  class Tag < ActiveRecord::Base
    establish_connection configurations['mephisto']
    has_many :taggings, :class_name => "Mephisto::Tagging"
  end
end
