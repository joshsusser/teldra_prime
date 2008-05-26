feed.entry(article, :published => article.published_at,
                    :url => post_url(*article.post_path_params) ) do |entry|
  entry.title(article.title)
  entry.author do |author|
    author.name(article.user.name)
  end
  article.tags.each do |tag|
    entry.category(:term => tag.name)
  end
  entry.summary(markdown(article.body), :type => 'html')
  entry.content(markdown(article.content), :type => 'html')
end
