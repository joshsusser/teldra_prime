module Mephisto
  class Tagging < ActiveRecord::Base
    establish_connection configurations['mephisto']
    belongs_to :tag, :class_name => "Mephisto::Tag"
    belongs_to :taggable, :class_name => "Mephisto::Article"
  end
end
