class ArticleSweeper < ActionController::Caching::Sweeper
  observe Article, Comment, Tagging
  
  def after_save(record)
    expire_record(record)
  end
  
  def after_destroy(record)
    expire_record(record)
  end
  
  def expire_record(record)
    if record.is_a?(Article) && record.post?
      expire_page(hash_for_root_path)
      expire_page(hash_for_feed_path)
    end
    article = record.is_a?(Article) ? record : record.article
    expire_page(hash_for_post_path(article.post_path_params_hash)) if article.post?
    expire_page(hash_for_page_path(article)) if article.page?
    if record.is_a?(Tagging)
      expire_page(hash_for_tags_path)
      expire_page(hash_for_tag_path(:tag => record.tag.name))
      expire_page(hash_for_tag_feed_path(:tag => record.tag.name))
    end
  end
end
