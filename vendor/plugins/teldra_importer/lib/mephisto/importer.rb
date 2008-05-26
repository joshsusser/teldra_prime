module Mephisto
  class Importer
    def initialize
      block = Proc.new { true }
      ::Comment.send(:define_method, :check_comment_expiration, block)
    end
    
    def import
      na = ::Article.count
      nc = ::Comment.count
      nt = ::Tag.count
      old_user = Mephisto::User.find_by_login("josh")
      raise "*** No Teldra user exists ***" unless teldra_user = User.find(:first) # find_by_login("josh")
      page_section = Mephisto::Section.find_by_name("pages")
      old_articles = Mephisto::Article.find(:all, :order => "created_at ASC")
      # puts old_articles.collect { |a| "#{a.title} - #{a.comments_count}" }
      old_articles.each do |old_article|
        body, extended = old_article.excerpt.blank? ? [old_article.body, ""] : [old_article.excerpt, old_article.body]
        article_attrs = {
          :kind => old_article.sections.include?(page_section) ? ::Article::PAGE : ::Article::POST,
          :user_id => teldra_user.id,
          :slug => old_article.permalink,
          :title => old_article.title,
          :body => body,
          :extended => extended,
          :comment_period => 30,
          :comments_count => 0,
          :created_at => old_article.created_at,
          :updated_at => old_article.updated_at,
          :published_at => old_article.published_at
        }
        new_article = ::Article.create!(article_attrs)
      
        old_article.comments.each do |old_comment|
          comment_attrs = {
            :user_id => old_comment.user_id.blank? ? nil : teldra_user.id, # only knows 1 user
            :author_name => old_comment.author,
            :author_email => old_comment.author_email,
            :author_url => old_comment.author_url,
            :author_ip => old_comment.author_ip,
            :body => old_comment.body,
            :created_at => old_comment.created_at
          }
          new_article.comments.create!(comment_attrs)
        
          new_tag_names = old_article.tags.collect(&:name) + old_article.sections.collect(&:name) - ["home"]
          new_article.tag_list = new_tag_names.join(", ")
        end
      end
      puts "*** Imported: #{::Article.count - na} Articles, #{::Comment.count - nc} Comments, #{::Tag.count - nt} Tags"
    end
  end
end