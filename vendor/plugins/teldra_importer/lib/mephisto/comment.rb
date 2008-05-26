module Mephisto
  class Comment < Mephisto::Content
    establish_connection configurations['mephisto']
    belongs_to :article, :class_name => "Mephisto::Article"
  end
end
