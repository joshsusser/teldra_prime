require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Admin::ArticlesController do
  scenario :basic

  before do
    login_as :admin
  end

  it "should get index" do
    get :index
    response.should be_success
    assigns[:articles].should_not be_nil
  end

  it "should show article with comments" do
    get :show, :id => articles(:body_post).id
    response.should be_success
    assigns[:article].should_not be_nil
    assigns[:comments].should have(articles(:body_post).comments.size).items
  end

  it "should get new" do
    get :new
    response.should be_success
    assigns[:article].should_not be_nil
  end

  it "should create post" do
    lambda do
      post :create, :article => articles(:body_post).attributes.except("id")
    end.should change(Article, :count)
    response.should redirect_to(admin_article_url(assigns[:article]))
    assigns[:article].user.id.should == session[:user_id]
    assigns[:article].kind.should_not be_nil
    assigns[:article].published_at.should_not be_nil
  end

  it "should get edit" do
    get :edit, :id => articles(:body_post).id
    response.should be_success
    assigns[:article].should == articles(:body_post)
  end

  it "should update post" do
    article = articles(:body_post)
    versions = article.versions.size
    put :update, :id => article.id, :article => { :extended => "and more content" }, :commit => "Save new version"
    response.should redirect_to(edit_admin_article_url(article))
    article.reload
    assigns[:article].should == article
    article.should have(versions + 1).versions
    article.extended.should == "and more content"
  end

  it "should update post without new version" do
    article = articles(:body_post)
    versions = article.versions.size
    put :update, :id => article.id, :article => { :extended => "and more content" }, :commit => "Save and keep same version"
    article.reload
    response.should redirect_to(edit_admin_article_url(article))
    article.reload
    assigns[:article].should == article
    article.should have(versions).versions
    article.extended.should == "and more content"
  end

  it "should destroy post" do
    lambda do
      delete :destroy, :id => articles(:body_post).id
    end.should change(Article, :count).by(-1)
    response.should redirect_to(admin_articles_url)
  end
end
