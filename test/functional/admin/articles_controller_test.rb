require File.dirname(__FILE__) + '/../../test_helper'

class Admin::ArticlesControllerTest < ActionController::TestCase
  scenario :basic

  should_authenticate_restful_actions

  context "when logged in" do
    setup do
      login_as :admin
    end

    context "GET /admin/articles (index)" do
      setup { get :index }
      should_render_template "index"
      should_assign_to :articles
      should "return all articles in reverse chron order" do
        assert_equal Article.count, assigns(:articles).size
        assert_sorted(assigns(:articles)) { |a,b| b.published_at <=> a.published_at }
      end
    end

    context "GET /admin/articles/:id (show)" do
      setup { get :show, :id => articles(:body_post).id }
      should_render_template "show"
      should_assign_to :article
      should "include all article's comments in reverse chron order" do
        assert_equal articles(:body_post).comments.size, assigns(:comments).size
        assert_sorted(assigns(:comments)) { |a,b| b.created_at <=> a.created_at }
      end
    end

    context "GET /admin/articles/new (new)" do
      setup { get :new }
      should_render_template "new"
      should_assign_to :article
    end

    context "POST /admin/articles (create post)" do
      setup do
        assert_difference('Article.count') do
          post :create, :article => articles(:body_post).attributes.except("id")
        end
      end
      should_redirect_to "admin_article_url(assigns(:article))"
      should "set inferred attributes of post" do
        assert_equal session[:user_id], assigns(:article).user.id
        assert_not_nil assigns(:article).kind
        assert_not_nil assigns(:article).published_at
      end
    end

    context "GET /admin/articles/:id/edit (edit)" do
      setup { get :edit, :id => articles(:body_post).id }
      should_render_template "edit"
      should_assign_to :article
    end

    context "PUT /admin/articles/:id (update)" do
      context "common" do
        setup { setup_update }
        should_redirect_to "edit_admin_article_url(@article)"
        should_assign_to :article
        should "update body" do
          assert_equal @article, assigns(:article)
          assert_equal "and more content", @article.extended
        end
      end

      context "with new version" do
        setup { setup_update "Save new version" }
        should "save a new version" do
          assert_equal(@num_versions + 1, @article.versions.size)
        end
      end

      context "without new version" do
        setup { setup_update "Save and keep same version" }
        should "save a new version" do
          assert_equal @num_versions, @article.versions.size
        end
      end
    end

    context "DELETE /admin/articles/:id" do
      setup do
        @article = articles(:body_post)
        get :destroy, :id => @article.id
      end
      should_set_the_flash_to "Article was deleted."
      should_redirect_to "admin_articles_url"
      should "destroy the article" do
        assert_nil Article.find_by_id(@article.id)
      end
    end
  end

  def setup_update(commit=nil)
    @article = articles(:body_post)
    @num_versions = @article.versions.size
    put :update, :id => @article.id, :article => { :extended => "and more content" }, :commit => commit
    @article.reload
  end

end