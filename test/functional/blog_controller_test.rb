require File.dirname(__FILE__) + '/../test_helper'

class BlogControllerTest < ActionController::TestCase
  scenario :blog

  def test_should_show_archives_in_index_view
    get :index
    assert_not_nil assigns(:archives)
    assert_select "ul#archives" do
      assert_select "li a[href=#{post_path(*articles(:welcome).post_path_params)}]"
    end
  end

  def test_should_not_show_meta_section_on_page_view
    about = articles(:about)
    post :page, :slug => about.slug
    assert_response :success
    assert_template 'show'
    assert_select 'ul.meta', false
  end

  def test_should_show_meta_section_on_post_view
    welcome = articles(:welcome)
    year, month, day, slug = *welcome.post_path_params
    post :show, :year => year, :month => month, :day => day, :slug => slug
    assert_response :success
    assert_template 'show'
    assert_select 'p.meta'
  end
 
  def test_should_not_show_comments_on_page_view
    about = articles(:about)
    post :page, :slug => about.slug
    assert_response :success
    assert_template 'show'
    assert_select 'ol#comments', false
  end
  
 def test_should_show_comments_on_post_view
    welcome = articles(:welcome)
    year, month, day, slug = *welcome.post_path_params
    post :show, :year => year, :month => month, :day => day, :slug => slug
    assert_response :success
    assert_template 'show'
    assert_select 'ol#comments'
  end

  def test_should_list_all_tags_that_have_articles
    tags = Tag.find_all_popular
    get :tags
    assert_equal tags, assigns(:tags)
  end
  
  def test_should_list_recent_articles_for_a_tag
    tag = tags(:meta)
    get :tag, :tag => tag.name
    assert_equal tag.articles.recent, assigns(:articles)
  end

  # sidebar

  def test_should_show_search_box
    get :index
    assert_select "div#search input#q"
  end
  
  def test_should_return_search_results
    get :search, :q => "body"
    assert_template "results"
    assert_not_nil assigns(:articles)
  end

  def test_should_return_empty_results_for_blank_query
    get :search, :q => ""
    assert_template "results"
    assert_equal [], assigns(:articles)
  end

  def test_should_show_tags_in_tag_cloud
    get :index
    assert_not_nil assigns(:tag_cloud)
    assert_select "p#tags"
  end

  # entering new comment

  def test_should_create_new_comment_on_post_view
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

  def test_should_not_create_new_comment_on_spammy_submission
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

  def test_should_set_user_id_of_logged_in_author_on_comment_creation
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

  # feed

  ATOM_CONTENT_TYPE = "application/atom+xml; charset=utf-8"

  def test_should_respond_to_main_atom_feed_request_with_atom_xml_document
    get :index, :format => 'atom'
    assert_equal ATOM_CONTENT_TYPE, @response.headers["type"]
    assert_select "entry", assigns(:articles).size
  end

  def test_should_respond_to_tag_atom_feed_request_with_atom_xml_document
    get :tag, :tag => 'meta', :format => 'atom'
    assert_equal ATOM_CONTENT_TYPE, @response.headers["type"]
    assert_select "entry", assigns(:articles).size
  end

  def test_should_respond_with_404_for_a_non_existent_tag_feed
    get :tag, :tag => 'meat', :format => 'atom'
    assert_response :not_found
  end
  
  def test_should_not_load_sidebar_data_for_atom_feeds
    get :index, :format => 'atom'
    assert_nil assigns(:tag_cloud)
    assert_nil assigns(:archives)
  end

end