class Article < ActiveRecord::Base
  
  class CommentNotAllowed < StandardError; end

  # kinds of articles
  POST = 0
  PAGE = 1
  
  after_create :set_tag_list_after_create
  
  simply_versioned

  belongs_to :user
  has_many :comments, :order => "comments.created_at"
  
  has_many :taggings, :dependent => :destroy
  has_many :tags, :through => :taggings, :order => "name"
  
  validates_presence_of :user_id
  validates_presence_of :slug
  validates_presence_of :title
  validates_presence_of :body
  
  has_finder :posts,      :conditions => "kind = #{POST}"
  has_finder :pages,      :conditions => "kind = #{PAGE}"
  has_finder :published,  :conditions => "published_at IS NOT NULL"
  has_finder :recent,     :conditions => "published_at IS NOT NULL", :order => "published_at DESC"
  has_finder :limit,      lambda { |limit| {:limit => limit} }

  def self.find_post_by_date_and_slug(year, month, day, slug)
    begin
      date = Date.new(year.to_i, month.to_i, day.to_i)
    rescue ArgumentError => e
      raise ActiveRecord::RecordNotFound, e.message
    end
    self.find(:first, :conditions => ["kind = #{POST} AND DATE(published_at) = ? AND slug = ?", date, slug])
  end

  def self.find_page_by_slug(slug)
    self.find(:first, :conditions => ["kind = #{PAGE} AND slug = ?", slug])
  end

  # Finds all articles that have all specified tags.
  # param slack allows for partial matches ordered by relevance
  #
  #   Article.find_all_by_tag_list [Tag, Tag, Tag]
  #   Article.find_all_by_tag_list ["tag1", "tag2", "tag3"]
  #   Article.find_all_by_tag_list "tag1, tag2, tag3"
  #   # => [Article, Article]
  def self.find_all_by_tag_list(tag_list, slack = 0)
    if tag_list.is_a?(String)
      tag_list = Tag.parse_to_tags(tag_list)
    else
      tag_list = tag_list.flatten.map { |t| t.is_a?(Tag) ? t : Tag.find_or_create_by_name(t) }
    end
    return [] if tag_list.empty?
    slack = [tag_list.size-1, slack].min
    order = "#{table_name}.published_at DESC"
    order = "COUNT(#{table_name}.id) DESC, " + order unless slack == 0
    find(:all, :readonly => false,
         :select => "#{table_name}.*",
         :joins => "INNER JOIN taggings t ON #{table_name}.id = t.article_id",
         :conditions => ["t.tag_id IN (?)", tag_list], :order => order,
         :group => "#{table_name}.id HAVING COUNT(#{table_name}.id) >= #{tag_list.size - slack}")
  end

  def self.search(query)
    if query.to_s.blank?
      []
    else
      tokens = query.split.collect { |t| "%#{t.downcase}%" }
      likes = (["(LOWER(title) LIKE ? OR LOWER(body) LIKE ? OR LOWER(extended) LIKE ?)"] * tokens.size).join(" AND ")
      self.published.find(:all, :conditions => [likes, *tokens.zip(tokens, tokens).flatten])
    end
  end

  def post?
    self.kind == POST
  end

  def page?
    self.kind == PAGE
  end
  
  def published?
    !self.published_at.nil?
  end

  def post_path_params
    raise ArgumentError, "can't generate post_path_params for articles that are not POST kind" if self.kind != POST
    [ published_at.year, published_at.month, published_at.mday, slug ]
  end
  
  def post_path_params_hash
    raise ArgumentError, "can't generate post_path_params for articles that are not POST kind" if self.kind != POST
    { :year => published_at.year, :month => published_at.month, :day => published_at.mday, :slug => slug }
  end


  def content
    cont = [self.body]
    cont << self.extended unless self.extended.blank?
    cont.join("\n\n")
  end
  
  ### comments ###
  
  # answer whether this kind of article supports comments (post vs page)
  def can_have_comments?
    self.post?
  end
  
  # answer whether comments are open or closed
  def allows_comments?
    self.can_have_comments? && self.comment_period_open?
  end
  
  def comment_period_open?
    days = self.comment_period || 0
    (days < 0) || (Time.now < self.published_at + days.days)
  end

  ### tag management ###

  def tag_list
    tags.collect { |t| t.name }.join(", ")
  end

  def tag_list=(tag_string)
    if self.new_record?
      @tag_list = tag_string
    else
      Tagging.set_on(self, tag_string)
      taggings.reset
      tags.reset
    end
  end
  
  def set_tag_list_after_create
    self.tag_list = @tag_list if @tag_list
  end

end
