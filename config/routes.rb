ActionController::Routing::Routes.draw do |map|

  map.root :controller => 'blog'
  map.feed 'feed.atom', :controller => 'blog', :format => 'atom'
  map.with_options :controller => 'blog' do |blog|
    blog.post ':year/:month/:day/:slug', :action => 'show',
      :year => /\d{4}/, :month => /\d{1,2}/, :day => /\d{1,2}/
    blog.page 'page/:slug', :action => 'page'
  end
  map.search    'search',        :controller => 'blog', :action => 'search'
  map.tags      'tags',          :controller => 'blog', :action => 'tags'
  map.tag       'tag/:tag',      :controller => 'blog', :action => 'tag'
  map.tag_feed  'tag/:tag.atom', :controller => 'blog', :action => 'tag', :format => 'atom'
  map.article_comments 'articles/:article_id/comments',
                       :controller => 'blog', :action => 'create_comment',
                       :conditions => { :method => :post }

  map.connect 'admin', :controller => 'admin/panel', :action => 'index'
  map.panel 'admin/panel', :controller => 'admin/panel', :action => 'index'
  map.namespace :admin, :prefix => '' do |admin|
    admin.resources :articles, :has_many => :comments
    admin.resources :comments
  end
  map.login  'login',  :controller => 'sessions', :action => 'new'
  map.logout 'logout', :controller => 'sessions', :action => 'destroy'
  map.resource  :session

  # backward compatibility with old Mephisto category links
  map.category ':tag', :controller => 'blog', :action => 'tag',
                :tag => /associations|biz|events|funny|goodies|hosting|meta|plugins|rails|sightings|tools/

  # Install the default routes as the lowest priority.
  # map.connect ':controller/:action/:id'
  # map.connect ':controller/:action/:id.:format'
end
