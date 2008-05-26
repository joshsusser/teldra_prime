module Mephisto
  class Article < Mephisto::Content
    establish_connection configurations['mephisto']

    has_many :comments, :class_name => "Mephisto::Comment"
    has_many :assigned_sections, :class_name => "Mephisto::AssignedSection"
    has_many :sections, :through => :assigned_sections, :order => 'sections.name', :class_name => "Mephisto::Section"
    has_many :taggings, :foreign_key => "taggable_id", :class_name => "Mephisto::Tagging"
    has_many :tags, :through => :taggings, :class_name => "Mephisto::Tag"
  end
end
