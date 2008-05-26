class Comment < ActiveRecord::Base
  belongs_to :article, :counter_cache => true
  belongs_to :user
  
  validates_existence_of :article
  validates_existence_of :user, :allow_nil => true
  validates_presence_of :author_name,  :unless => :user_id?
  # validates_presence_of :author_email, :unless => :user_id?
  validates_presence_of :body

  before_create  :check_comment_expiration

  attr :tofu

  def presentation_class
    case self.user_id
      when self.article.user_id
        "by-author"
      when nil
        "by-guest"
      else
        "by-user"
    end
  end

  def author_link
    name = self.author_name
    url = nil

    case
      when self.user
        name = self.user.name
      when self.author_url
        url = self.author_url
    end
    if url.blank?
     "<span>#{CGI::escapeHTML(name)}</span>"
    else
      %Q[<a href="#{CGI::escapeHTML(url)}">#{CGI::escapeHTML(name)}</a>]
    end
  end
  
  def check_comment_expiration
    raise Article::CommentNotAllowed unless article.comment_period_open?
  end
end
