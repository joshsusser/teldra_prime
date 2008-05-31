require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Admin::CommentsController do
  it_should_behave_like "an authenticated, RESTful controller"
end

describe Admin::CommentsController do
  scenario :blog

  before do
    login_as :admin
  end

  it "should list all comments in reverse chron order" do
    get :index
    response.should be_success
    assigns[:comments].should have(Comment.count).items
    assigns[:comments].should be_sorted { |a,b| b.created_at <=> a.created_at }
  end

  it "should list all comments in reverse chron order with pagination" do
    welcome = articles(:new_release)
    1.upto 100 do |i|
      comment = welcome.comments.create(:author_name => "Bob", :body => "Slack off!")
      Comment.update_all("created_at = '#{i.minutes.ago.to_s(:db)}'", "id = #{comment.id}")
    end
    get :index, :page => 2
    response.should be_success
    assigns[:comments].should have(Comment.per_page).items
    assigns[:comments].should be_sorted { |a,b| b.created_at <=> a.created_at }
  end

  it "should delete a comment" do
    comment = comments(:stalker_welcome)
    lambda do
      get :destroy, :id => comment.id
    end.should change(Comment, :count).by(-1)
    response.should be_redirect
    Comment.find_by_id(comment.id).should be_nil
  end

end