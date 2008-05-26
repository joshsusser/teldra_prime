class BlogController < ApplicationController
  
  caches_page :index, :tags, :tag, :show, :page
  cache_sweeper :article_sweeper, :only => [:create_comment]

  before_filter :setup_sidebar, :except => [:create_comment]
  
  # main blog page - show recent posts (short form)
  def index
    respond_to do |format|
      format.html do
        @articles = Article.posts.recent.limit(5)
        @archives = Article.posts.recent
      end
      format.atom { @articles = Article.posts.recent.limit(10) }
    end
  end

  # list all tags
  def tags
    @tags = Tag.find_all_popular
  end

  # show posts for :tag (result list form)
  def tag
    if @tag = Tag.find_by_name(params[:tag])
      @articles = Article.find_all_by_tag_list([@tag])
      respond_to do |format|
        format.html
        format.atom
      end
    else
      head :not_found
    end
  end
  
  def search
    @articles = Article.search(params[:q])
    render :action => 'results'
  end

  # show post (extended form)
  def show
    @article = Article.find_post_by_date_and_slug(params[:year], params[:month], params[:day], params[:slug])
    @page_title = @article.title
  end

  # show page
  def page
    @article = Article.find_page_by_slug(params[:slug])
    @page_title = @article.title
    render :action => 'show'
  end

  def create_comment
    @article = Article.find(params[:article_id])
    params[:comment].merge!(:author_ip => request.remote_ip, :user_id => session[:user_id])
    if check_comment_spam(params[:comment])
      @comment = @article.comments.build(params[:comment])
      if @comment.save
        redirect_to post_url(*@article.post_path_params)
      else
        flash[:warning] = "COMMENT ERROR" # FIXME comment missing something
        redirect_to post_url(*@article.post_path_params)
      end
    else
      Reject.create(params[:comment].merge(:article_id => @article.id))
      redirect_to post_url(*@article.post_path_params)
    end
  end
  
  private
  
  def setup_sidebar
    unless request.format.to_sym == :atom
      @tag_cloud = Tag.find_all_popular
    end
  end

  def check_comment_spam(data)
    if data[:body].blank?
      data[:body] = data.delete(:tofu)
    else
      false
    end
  end
end
