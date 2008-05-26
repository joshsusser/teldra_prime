module Mephisto
  class Content < ActiveRecord::Base
    establish_connection configurations['mephisto']
    belongs_to :user, :class_name => "Mephisto::User"
  end
end
