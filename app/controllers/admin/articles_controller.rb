class Admin::ArticlesController < ApplicationController
  layout "admin"
  
  before_filter :login_required
  
  cache_sweeper :article_sweeper, :only => [:create, :update, :destroy]
  
  # GET /admin/articles
  def index
    @articles = Article.find(:all, :order => "created_at DESC")
  end

  # GET /admin/articles/:id
  def show
    @article = Article.find(params[:id])
    @comments = @article.comments
  end

  # GET /admin/articles/new
  def new
    @article = Article.new
  end

  # GET /admin/articles/:id/edit
  def edit
    @article = Article.find(params[:id])
  end

  # POST /admin/articles
  def create
    @article = Article.new(params[:article])
    @article.user_id = session[:user_id]
    
    @article.published_at = Time.now

    if @article.save
      flash[:success] = 'Article was successfully created.'
      redirect_to([:admin, @article])
    else
      # flash[:warning] = 'Article could not be created.'
      render :action => "new"
    end
  end

  # PUT /admin/articles/:id
  def update
    @article = Article.find(params[:id])
    
    save_new_version = !(params[:commit].to_s !~ /save new version/i)
    if @article.with_versioning(save_new_version) { |a| a.update_attributes(params[:article]) }
      flash[:success] = 'Article was successfully updated.'
      redirect_to edit_admin_article_url(@article)
    else
      # flash[:warning] = 'Article could not be updated.'
      render :action => "edit"
    end
  end

  # DELETE /admin/articles/:id
  def destroy
    @article = Article.find(params[:id])
    @article.destroy

    flash[:success] = 'Article was deleted.'
    redirect_to(admin_articles_url)
  end
end
