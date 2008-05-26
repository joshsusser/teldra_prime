class Tagging < ActiveRecord::Base
  belongs_to :article
  belongs_to :tag, :counter_cache => true
  
  validates_presence_of :article_id, :tag_id

  class << self
    # Sets the tags on the article.  Only adds new tags and deletes old tags.
    #
    #   Tagging.set_on @article, 'foo, bar'
    def set_on(article, tag_list)
      current_tags  = article.tags
      new_tags      = Tag.parse_to_tags(tag_list)
      remove_from article, (current_tags - new_tags)
      add_to      article, (new_tags - current_tags)
    end
  
    # Deletes tags from the article
    #
    #   Tagging.remove_from @article, [1, 2, 3]
    #   Tagging.remove_from @article, [Tag, Tag, Tag]
    def remove_from(article, tags)
      unless tags.blank?
        tag_ids = tags.collect { |t| t.is_a?(Tag) ? t.id : t }
        destroy_all ['article_id = ? and tag_id in (?)', article.id, tag_ids] # use destroy_all to maintain counter_cache in tag
      end
    end

    # Adds tags to the article
    #
    #   Tagging.add_to @article, [Tag, Tag, Tag]
    def add_to(article, tags)
      unless tags.blank?
        tags.each do |tag|
          next if article.tags.include?(tag)
          create!(:article => article, :tag => tag)
        end
      end
    end
  end

end
