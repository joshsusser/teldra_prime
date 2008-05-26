module Mephisto
  class Section < ActiveRecord::Base
    establish_connection configurations['mephisto']
  end
end
