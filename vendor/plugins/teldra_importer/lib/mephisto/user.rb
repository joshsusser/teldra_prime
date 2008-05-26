module Mephisto
  class User < ActiveRecord::Base
    establish_connection configurations['mephisto']
  end
end
