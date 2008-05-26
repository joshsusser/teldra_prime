module BlogHelper
  
  def doc_title
    if @page_title
      h("#{SITE_TITLE} - #{@page_title}")
    else
      h(SITE_TITLE)
    end
  end
  
  def link_to_article(article)
    link_to h(article.title), article.post? ? post_path(*article.post_path_params) : page_path(article.slug)
  end

  def links_to_tags(tags)
    if tags.blank?
      "[none]"
    else
      tags.collect { |tag| link_to h(tag.name), tag_path(tag) }.join(", ")
    end
  end
  
  def tag_cloud
    @tag_cloud.collect { |tag| link_to(h(tag.name), tag_path(tag)) }.join(" ")
    # content_tag(:ul, 
    #   @tag_cloud.collect { |tag| content_tag(:li, link_to(h(tag.name), tag_path(tag))) }.join("\n"),
    #   :id => "tags")
  end
  
  def archive_list
    current_date = nil
    list = []
    @archives.each do |post|
      date = Date.new(post.published_at.year, post.published_at.month, 1)
      if date != current_date
        current_date = date
        list << content_tag(:li, current_date.strftime("%B %Y"), :class => "month")
      end
      list << content_tag(:li, link_to(h(post.title), post_path(*post.post_path_params)), :class => "post")
    end
    list.join("\n")
  end
end
