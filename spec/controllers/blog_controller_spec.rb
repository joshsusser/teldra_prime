require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe BlogController do
  scenario :blog

  describe "basic viewing" do
    it "should show archives in index view" do
      get :index
      assigns(:archives).should_not be_nil
      response.should have_tag("ul#archives") do
        with_tag "li a[href=#{post_path(*articles(:welcome).post_path_params)}]"
      end
    end

    it "should not show meta section on Page view" do
      about = articles(:about)
      post :page, :slug => about.slug
      response.should be_success
      response.should render_template('show')
      response.should_not have_tag('p.meta')
    end

    it "should show meta section on Post view" do
      welcome = articles(:welcome)
      year, month, day, slug = *welcome.post_path_params
      post :show, :year => year, :month => month, :day => day, :slug => slug
      response.should be_success
      response.should render_template('show')
      response.should have_tag('p.meta')
    end

    it "should not show comments on Page view" do
      about = articles(:about)
      post :page, :slug => about.slug
      response.should be_success
      response.should render_template('show')
      response.should_not have_tag('ol#comments')
    end

    it "should show comments on Post view" do
      welcome = articles(:welcome)
      year, month, day, slug = *welcome.post_path_params
      post :show, :year => year, :month => month, :day => day, :slug => slug
      response.should be_success
      response.should render_template('show')
      response.should have_tag('ol#comments')
    end

    it "should list all tags that have articles" do
      tags = Tag.find_all_popular
      get :tags
      assigns(:tags).should == tags
    end

    it "should list recent articles for a tag" do
      tag = tags(:meta)
      get :tag, :tag => tag.name
      assigns(:articles).should == tag.articles.recent
    end
  end

  describe "sidebar" do
    it "should show search box" do
      get :index
      response.should have_tag("div#search input#q")
    end

    it "should return search results" do
      get :search, :q => "body"
      response.should render_template('results')
      assigns(:articles).should_not be_empty
    end

    it "should return empty results for blank query" do
      get :search, :q => ""
      response.should render_template('results')
      assigns(:articles).should be_empty
    end

    it "should show tags in tag cloud" do
      get :index
      assigns(:tag_cloud).should_not be_empty
      response.should have_tag("p#tags")
    end
  end

  describe "entering new comment" do
    it "should create new comment on Post view" do
      update_post = articles(:update)
      lambda do
        post :create_comment, :article_id => update_post.to_param, :comment => comment_options
      end.should change(Comment, :count)

      response.should redirect_to(post_path(*assigns(:article).post_path_params))

      # should be follow_redirect
      ps = update_post.post_path_params
      get :show, :year => ps[0], :month => ps[1], :day => ps[2], :slug => ps[3]

      new_comment = Comment.find_by_author_name(comment_options[:author_name])
      new_comment.author_ip.should_not be_blank
      response.should have_tag("li#comment_#{new_comment.id}")
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

      response.should redirect_to(post_path(*assigns(:article).post_path_params))
    end

    it "should set user_id of logged in author on comment creation" do
      update_post = articles(:update)

      post :create_comment, :article_id => update_post.to_param, :comment => comment_options
      assigns(:comment).user_id.should be_nil

      login_as(:admin)
      post :create_comment, :article_id => update_post.to_param, :comment => comment_options
      assigns(:comment).user_id.should == users(:admin).id
    end

    def comment_options(options = {})
      { :author_name => "Bob Dobbs",
        :author_email => "bob@slack.com",
        :author_url => "http://bob.slack.com",
        :tofu => "Slack off! Quit your job!"
      }.merge(options)
    end
  end

  describe "feed" do

    ATOM_CONTENT_TYPE = "application/atom+xml; charset=utf-8"

    it "should respond to main atom feed request with atom xml document" do
      get :index, :format => 'atom'
      response.headers["type"].should == ATOM_CONTENT_TYPE
      response.should have_tag("entry", assigns(:articles).size)
    end

    it "should respond to tag atom feed request with atom xml document" do
      get :tag, :tag => 'meta', :format => 'atom'
      response.headers["type"].should == ATOM_CONTENT_TYPE
      response.should have_tag("entry", assigns(:articles).size)
    end

    it "should respond with 404 for a non-existent tag feed" do
      get :tag, :tag => 'meat', :format => 'atom'
      response.code.should == "404"
    end

    it "should not load sidebar data for atom feeds" do
      get :index, :format => 'atom'
      assigns(:tag_cloud).should be_nil
      assigns(:archives).should be_nil
    end
  end
end
