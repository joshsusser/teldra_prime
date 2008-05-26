require File.dirname(__FILE__) + '/../../test_helper'

describe "Admin::CommentsController" do
  scenario :blog

  setup do
    use_controller Admin::CommentsController
    login_as :admin
  end

  it "should list all comments in reverse chron order" do
    get :index
    assert_response :success
    assert_nil assigns(:article)
    assert_not_nil assigns(:comments)
    assert_equal Comment.count, assigns(:comments).size
  end

  it "should list all comments in reverse chron order with pagination" do
    welcome = articles(:new_release)
    100.times { welcome.comments.create(:author_name => "Bob", :body => "Slack off!") }
    get :index, :page => 2
    assert_response :success
    assert_nil assigns(:article)
    assert_not_nil assigns(:comments)
    assert_equal Comment.per_page, assigns(:comments).size
  end

  it "should delete a comment" do
    comment = comments(:stalker_welcome)
    assert_difference 'Comment.count', -1 do
      get :destroy, :id => comment.id
    end
    assert_nil Comment.find_by_id(comment.id)
    assert_response :found
  end

end
