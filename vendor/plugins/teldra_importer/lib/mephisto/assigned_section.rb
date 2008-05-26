module Mephisto
  class AssignedSection < ActiveRecord::Base
    establish_connection configurations['mephisto']
    belongs_to :article, :class_name => "Mephisto::Article"
    belongs_to :section, :class_name => "Mephisto::Section"
  end
end
