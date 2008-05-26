class Admin::CommentsController < ApplicationController
  layout "admin"
  
  before_filter :login_required
  
  cache_sweeper :article_sweeper, :only => [:destroy]

  # GET /admin/comments
  def index
    @comments = Comment.paginate(:all, :page => params[:page], :order => "created_at DESC")
  end

  # DELETE /admin/comments/:id
  def destroy
    @comment = Comment.find(params[:id])
    @comment.destroy
    redirect_to request.referer || admin_comments_url # nil in tests
  end
end
