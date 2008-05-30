require File.dirname(__FILE__) + '/../test_helper'

class BlogControllerTest < ActionController::TestCase
  scenario :blog

  context "main blog view (index)" do
    setup { get :index }

    should_assign_to :articles
    should "show 5 most recent articles in reverse chron order" do
      assert_equal 5, assigns(:articles).size
      assert_sorted(assigns(:articles)) { |a,b| b.published_at <=> a.published_at }
    end

    should_assign_to :archives
    should "show archive list in reverse chron order" do
      assert_sorted(assigns(:archives)) { |a,b| b.published_at <=> a.published_at }
      assert_select "ul#archives" do
        assert_select "li a[href=#{post_path(*articles(:welcome).post_path_params)}]"
      end
    end

    should "show sidebar search box" do
      assert_select "div#search input#q"
    end

    should "show tags in tag cloud" do
      assert_not_nil assigns(:tag_cloud)
      assert_select "p#tags"
    end
  end

  context "show Page" do
    setup do
      about = articles(:about)
      get :page, :slug => about.slug
    end
    should_render_template "show"
    should "not show meta section" do
      assert_select 'ul.meta', false
    end
    should "not show comments" do
      assert_select 'ol#comments', false
    end
  end

  context "show Post" do
    setup do
      welcome = articles(:welcome)
      year, month, day, slug = *welcome.post_path_params
      post :show, :year => year, :month => month, :day => day, :slug => slug
    end
    should_render_template "show"
    should "show meta section" do
      assert_select 'p.meta'
    end
    should "show comments" do
      assert_select 'ol#comments'
    end
  end

  context "tags" do
    should "list all tags that have articles"do
      get :tags
      assert_equal Tag.find_all_popular, assigns(:tags)
    end
    should "list recent articles for a tag" do
      tag = tags(:meta)
      get :tag, :tag => tag.name
      assert_equal tag.articles.recent, assigns(:articles)
    end
  end

  context "searching" do
    context "valid query" do
      setup { get :search, :q => "body" }
      should_render_template "results"
      should "return non-empty results" do
        assert !assigns(:articles).empty?
      end
    end
    context "empty query" do
      setup { get :search, :q => "" }
      should_render_template "results"
      should "return non-empty results" do
        assert_equal [], assigns(:articles)
      end
    end
  end

  context "entering new comment" do
    should "create new comment on a post" do
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

    should "not create new comment on spammy submission" do
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

    should "not set user_id when nobody logged in" do
      logout
      update_post = articles(:update)
      post :create_comment, :article_id => update_post.to_param, :comment => comment_options
      assert_nil assigns(:comment).user_id
    end

    should "set user_id of logged in author on comment creation" do
      login_as(:admin)
      update_post = articles(:update)
      post :create_comment, :article_id => update_post.to_param, :comment => comment_options
      assert_equal users(:admin).id, assigns(:comment).user_id
    end
  end

  def comment_options(options = {})
    { :author_name => "Bob Dobbs",
      :author_email => "bob@slack.com",
      :author_url => "http://bob.slack.com",
      :tofu => "Slack off! Quit your job!"
    }.merge(options)
  end

  ATOM_CONTENT_TYPE = "application/atom+xml; charset=utf-8"

  context "feed" do
    context "content" do
      setup { get :index, :format => 'atom' }
      should "respond to main atom feed request with atom xml document" do
        assert_equal ATOM_CONTENT_TYPE, @response.headers["type"]
        assert_select "entry", assigns(:articles).size
      end
      should_not_assign_to :archives
      should_not_assign_to :tag_cloud
    end

    context "request for atom tag feed" do
      setup { get :tag, :tag => 'meta', :format => 'atom' }
      should "respond with contents" do
        assert_equal ATOM_CONTENT_TYPE, @response.headers["type"]
        assert_select "entry", assigns(:articles).size
      end
    end

    context "request for non-existent tag feed" do
      setup { get :tag, :tag => 'meat', :format => 'atom' }
      should_respond_with :not_found
    end
  end

end
