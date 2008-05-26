class Tag < ActiveRecord::Base
  has_many :taggings, :dependent => :destroy
  has_many :articles, :through => :taggings

  validates_uniqueness_of :name
  
  def self.find_all_popular
    self.find(:all, :conditions => "taggings_count > 0", :order => "taggings_count DESC, name ASC")
  end

  class << self
    # Parses comma separated tag list and returns tags for them.
    #
    #   Tag.parse_to_tags('a, b, c')
    #   # => [Tag, Tag, Tag]
    def parse_to_tags(list)
      find_or_create(parse(list))
    end
    
    # Parses a comma separated list of tags into tag names
    #
    #   Tag.parse('a, b, c')
    #   # => ['a', 'b', 'c']
    def parse(list)
      list.gsub(/[^\w\ ,]+/, '').squeeze(" ").downcase.split(",").map(&:strip).reject { |s| s.blank? }.uniq
    end
    
    # Returns Tags from an array of tag names
    # 
    #   Tag.find_or_create(['a', 'b', 'c'])
    #   # => [Tag, Tag, Tag]
    def find_or_create(tag_names)
      transaction do
        found_tags = find(:all, :conditions => ['name IN (?)', tag_names])
        found_tags + (tag_names - found_tags.collect(&:name)).collect { |s| create!(:name => s) }
      end
    end
  end

  def ==(object)
    super || name == object.to_s
  end
  
  def to_s
    name
  end

  def to_param
    name.gsub(/ /,'+')
  end

end
