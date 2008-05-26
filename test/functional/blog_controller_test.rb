require File.dirname(__FILE__) + '/../test_helper'

describe "BlogController" do
  scenario :blog

  setup do
    use_controller BlogController
  end

  it "should show archives in index view" do
    get :index
    assert_not_nil assigns(:archives)
    assert_select "ul#archives" do
      assert_select "li a[href=#{post_path(*articles(:welcome).post_path_params)}]"
    end
  end

  it "should not show meta section on Page view" do
    about = articles(:about)
    post :page, :slug => about.slug
    assert_response :success
    assert_template 'show'
    assert_select 'ul.meta', false
  end

  it "should show meta section on Post view" do
    welcome = articles(:welcome)
    year, month, day, slug = *welcome.post_path_params
    post :show, :year => year, :month => month, :day => day, :slug => slug
    assert_response :success
    assert_template 'show'
    assert_select 'p.meta'
  end
 
  it "should not show comments on Page view" do
    about = articles(:about)
    post :page, :slug => about.slug
    assert_response :success
    assert_template 'show'
    assert_select 'ol#comments', false
  end
  
 it "should show comments on Post view" do
    welcome = articles(:welcome)
    year, month, day, slug = *welcome.post_path_params
    post :show, :year => year, :month => month, :day => day, :slug => slug
    assert_response :success
    assert_template 'show'
    assert_select 'ol#comments'
  end

  it "should list all tags that have articles" do
    tags = Tag.find_all_popular
    get :tags
    assert_equal tags, assigns(:tags)
  end
  
  it "should list recent articles for a tag" do
    tag = tags(:meta)
    get :tag, :tag => tag.name
    assert_equal tag.articles.recent, assigns(:articles)
  end

end

describe "BlogController sidebar" do
  scenario :blog

  setup do
    use_controller BlogController
  end
  
  it "should show search box" do
    get :index
    assert_select "div#search input#q"
  end
  
  it "should return search results" do
    get :search, :q => "body"
    assert_template "results"
    assert_not_nil assigns(:articles)
  end

  it "should return empty results for blank query" do
    get :search, :q => ""
    assert_template "results"
    assert_equal [], assigns(:articles)
  end

  it "should show tags in tag cloud" do
    get :index
    assert_not_nil assigns(:tag_cloud)
    assert_select "p#tags"
  end
end

describe "BlogController entering new comment" do
  scenario :blog

  setup do
    use_controller BlogController
  end

  it "should create new comment on Post view" do
    update_post = articles(:update)
    assert_difference('Comment.count') do
      assert_difference('update_post.comments.count') do
        post :create_comment, :article_id => update_post.to_param, :comment => comment_options
      end
    end

    assert_redirected_to post_path(*assigns(:article).post_path_params)

    # should be follow_redirect
    ps = update_post.post_path_params
    get :show, :year => ps[0], :month => ps[1], :day => ps[2], :slug => ps[3]
    
    new_comment = Comment.find_by_author_name(comment_options[:author_name])
    assert !new_comment.author_ip.blank?
    assert_select "li#comment_#{new_comment.id}"
  end
  
  it "should not create new comment on spammy submission" do
    update_post = articles(:update)
    assert_no_difference('Comment.count') do
      assert_no_difference('update_post.comments.count') do
        assert_difference('Reject.count') do
          post :create_comment, :article_id => update_post.to_param, :comment => comment_options(:body => "spam spam spam")
        end
      end
    end
  
    assert_redirected_to post_path(*assigns(:article).post_path_params)
  end
  
  it "should set user_id of logged in author on comment creation" do
    update_post = articles(:update)
    
    post :create_comment, :article_id => update_post.to_param, :comment => comment_options
    assert_nil assigns(:comment).user_id

    login_as(:admin)
    post :create_comment, :article_id => update_post.to_param, :comment => comment_options
    assert_equal users(:admin).id, assigns(:comment).user_id
  end

  def comment_options(options = {})
    { :author_name => "Bob Dobbs",
      :author_email => "bob@slack.com",
      :author_url => "http://bob.slack.com",
      :tofu => "Slack off! Quit your job!"
    }.merge(options)
  end
end

describe "BlogController feed" do
  scenario :blog

  ATOM_CONTENT_TYPE = "application/atom+xml; charset=utf-8"

  setup do
    use_controller BlogController
  end

  it "should respond to main atom feed request with atom xml document" do
    get :index, :format => 'atom'
    assert_equal ATOM_CONTENT_TYPE, @response.headers["type"]
    assert_select "entry", assigns(:articles).size
  end

  it "should respond to tag atom feed request with atom xml document" do
    get :tag, :tag => 'meta', :format => 'atom'
    assert_equal ATOM_CONTENT_TYPE, @response.headers["type"]
    assert_select "entry", assigns(:articles).size
  end

  it "should respond with 404 for a non-existent tag feed" do
    get :tag, :tag => 'meat', :format => 'atom'
    assert_response :not_found
  end
  
  it "should not load sidebar data for atom feeds" do
    get :index, :format => 'atom'
    assert_nil assigns(:tag_cloud)
    assert_nil assigns(:archives)
  end

end