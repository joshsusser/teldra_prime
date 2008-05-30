require File.dirname(__FILE__) + '/../../test_helper'

class Admin::CommentsControllerTest < ActionController::TestCase
  scenario :blog

  should_authenticate_restful_actions

  context "when logged in" do
    setup do
      login_as :admin
    end

    context "GET /admin/comments" do
      setup { get :index }
      should_render_template "index"
      should_assign_to :comments
      should_not_assign_to :article
      should "return all comments in reverse chron order" do
        assert_equal Comment.count, assigns(:comments).size
        assert_sorted(assigns(:comments)) { |a,b| b.created_at <=> a.created_at }
      end
    end

    context "GET /admin/comments?page=2" do
      setup { get :index, :page => 2 }
      should "be paginated" do
        assert_equal 2, assigns(:comments).current_page
      end
    end

    context "DELETE /admin/comments/:id" do
      setup do
        @comment = comments(:stalker_welcome)
        delete :destroy, :id => @comment.id
      end
      should_not_set_the_flash
      should_redirect_to "admin_comments_url"
      should "destroy the comment" do
        assert_nil Comment.find_by_id(@comment.id)
      end
    end
  end
end