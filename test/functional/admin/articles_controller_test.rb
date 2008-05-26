require File.dirname(__FILE__) + '/../../test_helper'

describe "Admin::ArticlesController" do
  scenario :basic
  
  setup do
    use_controller Admin::ArticlesController
    login_as :admin
  end
  
  it "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:articles)
  end
  
  it "should show article with comments" do
    get :show, :id => articles(:body_post).id
    assert_response :success
    assert_not_nil assigns(:article)
    assert_equal articles(:body_post).comments.size, assigns(:comments).size
  end

  def test_should_get_new
    get :new
    assert_response :success
  end
  
  def test_should_create_post
    assert_difference('Article.count') do
      post :create, :article => articles(:body_post).attributes.except("id")
      assert_equal session[:user_id], assigns(:article).user.id
      assert_not_nil assigns(:article).kind
      assert_not_nil assigns(:article).published_at
    end
  
    assert_redirected_to admin_article_url(assigns(:article))
  end
  
  def test_should_show_post
    get :show, :id => articles(:body_post).id
    assert_response :success
  end
  
  def test_should_get_edit
    get :edit, :id => articles(:body_post).id
    assert_response :success
  end
  
  def test_should_update_post
    article = articles(:body_post)
    versions = article.versions.size
    put :update, :id => article.id, :article => { :extended => "and more content" }, :commit => "Save new version"
    article.reload
    assert_equal article, assigns(:article)
    assert_equal (versions + 1), article.versions.size
    assert_equal "and more content", article.extended
    assert_redirected_to edit_admin_article_url(article)
  end
  
  def test_should_update_post_without_new_version
    article = articles(:body_post)
    versions = article.versions.size
    put :update, :id => article.id, :article => { :extended => "and more content" }, :commit => "Save and keep same version"
    article.reload
    assert_equal article, assigns(:article)
    assert_equal versions, article.versions.size
    assert_equal "and more content", article.extended
    assert_redirected_to edit_admin_article_url(article)
  end
  
  def test_should_destroy_post
    assert_difference('Article.count', -1) do
      delete :destroy, :id => articles(:body_post).id
    end
  
    assert_redirected_to admin_articles_url
  end
end
