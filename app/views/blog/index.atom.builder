atom_feed(:schema_date => "2006-02-27") do |feed|
  feed.title SITE_TITLE
  feed.updated @articles.first.published_at
  render :partial => 'article', :collection => @articles, :locals => { :feed => feed }
end
