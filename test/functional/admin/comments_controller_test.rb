require File.dirname(__FILE__) + '/../../test_helper'

class AuthenticatedCommentsControllerTest < ActionController::TestCase
  include AuthenticatedRestfulTests
  tests Admin::CommentsController
end

class Admin::CommentsControllerTest < ActionController::TestCase
  scenario :blog
  
  def setup
    super
    login_as :admin
  end

  def test_should_list_all_comments_in_reverse_chron_order
    get :index
    assert_response :success
    assert_nil assigns(:article)
    assert_not_nil assigns(:comments)
    assert_equal Comment.count, assigns(:comments).size
  end

  def test_should_list_all_comments_in_reverse_chron_order_with_pagination
    welcome = articles(:new_release)
    100.times { welcome.comments.create(:author_name => "Bob", :body => "Slack off!") }
    get :index, :page => 2
    assert_response :success
    assert_nil assigns(:article)
    assert_not_nil assigns(:comments)
    assert_equal Comment.per_page, assigns(:comments).size
  end

  def test_should_delete_a_comment
    comment = comments(:stalker_welcome)
    assert_difference 'Comment.count', -1 do
      get :destroy, :id => comment.id
    end
    assert_nil Comment.find_by_id(comment.id)
    assert_response :found
  end

end
