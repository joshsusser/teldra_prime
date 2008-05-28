require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Article do
  describe "Blog list" do
    scenario :blog

    it "should find only posts in reverse chron order" do
      articles = Article.posts.recent
      articles.all? { |a| a.kind == Article::POST }.should be_true
      articles.should == articles.sort {|a,b| b.published_at <=> a.published_at}
    end

    it "should find specified number of recent posts" do
      articles = Article.posts.recent
      articles.size.should == Article.find(:all).select { |a| a.post? && a.published_at? }.size
      articles = Article.posts.limit(2)
      articles.should have(2).items
    end
  end

  describe "#find_post_by_date_and_slug" do
    scenario :blog

    it "should find the post with slug published on given date" do
      update = articles(:update)
      post = Article.find_post_by_date_and_slug(*update.post_path_params)
      post.should == update
    end

    it "should raise error when called with bogus date" do
      update = articles(:update)
      lambda {
        Article.find_post_by_date_and_slug("2007", "15", "45", update.slug)
      }.should(
        raise_error(ActiveRecord::RecordNotFound, "invalid date")
      )
    end
  end

  describe "#find_page_by_slug" do
    scenario :blog

    it "should find the page with slug" do
      about = articles(:about)
      page = Article.find_page_by_slug(about.slug)
      page.should == about
    end
  end

  describe "Published post.post_path_params" do
    scenario :blog

    it "should return array of params for creating url" do
      article = articles(:welcome)
      date = article.published_at
      article.post_path_params.should == [date.year, date.month, date.mday, article.slug]
    end

    it "should raise when called on a non-post article" do
      page = articles(:about)
      lambda { page.post_path_params }.should raise_error(ArgumentError)
    end
  end

  describe "Article with content" do
    scenario :basic

    it "should return #content as body and extended" do
      article = articles(:extended_post)
      content = article.body + "\n\n" + article.extended
      article.content.should == content
    end

    it "should return #content body if extended is blank" do
      article = articles(:body_post)
      content = article.body
      article.content.should == content
    end
  end

  describe "Article comments" do
    scenario :blog

    it "should allow comments for a Post article with open comments" do
      post = Article.new(:kind => Article::POST, :published_at => Time.now)

      tomorrow = 1.day.from_now
      next_year = 1.year.from_now

      post.comment_period = 7
      Time.stubs(:now).returns(tomorrow)
      post.allows_comments?.should be_true

      post.comment_period = -1
      Time.stubs(:now).returns(next_year)
      post.allows_comments?.should be_true
    end

    it "should not allow comments for a Post article with closed comments" do
      post = Article.new(:kind => Article::POST, :published_at => Time.now)

      tomorrow = 1.day.from_now
      next_year = 1.year.from_now

      post.comment_period = 0
      Time.stubs(:now).returns(tomorrow)
      post.allows_comments?.should_not be_true

      post.comment_period = 30
      Time.stubs(:now).returns(next_year)
      post.allows_comments?.should_not be_true
    end

    it "should never allow comments for a Page article" do
      page = articles(:about)
      page.allows_comments?.should_not be_true
    end
  end

  describe "Article tags" do
    scenario :tags

    it "should add tags when assigning to tag_list" do
      article = articles(:untagged)
      article.tags.should be_empty

      article.tag_list = "test1"
      article.tag_list.should == "test1"
      Tagging.find_all_by_article_id(article.id).should have(1).items

      article.tag_list = "test1, test1, test1"
      article.tag_list.should == "test1"
      Tagging.find_all_by_article_id(article.id).should have(1).items

      article.tag_list = "test1, test2, test3"
      article.tag_list.should == "test1, test2, test3"
      Tagging.find_all_by_article_id(article.id).should have(3).items

      article.tag_list = "test1, test3"
      article.tag_list.should == "test1, test3"
      Tagging.find_all_by_article_id(article.id).should have(2).items

      article.tag_list = "testM, testZ, testA, testJ"
      article.tag_list.should == "testa, testj, testm, testz"
      Tagging.find_all_by_article_id(article.id).should have(4).items

      article.tag_list = ""
      article.tag_list.should == ""
      Tagging.find_all_by_article_id(article.id).should be_empty
    end

    it "should set tags on article that is a new record" do
      article = Article.create!(:user_id => 1, :title => "test", :slug => "test", :body => "test", :tag_list => "test, case")
      article.tag_list.should == "case, test"
    end

    it "should find articles by list of tags" do
      welcome = articles(:welcome)
      goodbye = articles(:goodbye)
      san_francisco = tags(:san_francisco)
      chocolate = tags(:chocolate)

      [ [chocolate], ["chocolate"], "chocolate" ].each do |tag_list|
        found = Article.find_all_by_tag_list(tag_list)
        found.should have(1).articles
        found.should include(welcome)
      end

      [ [san_francisco], ["san francisco"], "san francisco" ].each do |tag_list|
        found = Article.find_all_by_tag_list(tag_list)
        found.should have(2).articles
        found.should include(welcome, goodbye)
      end

      [ [chocolate, san_francisco], ["chocolate","san francisco"], "chocolate, san francisco" ].each do |tag_list|
        found = Article.find_all_by_tag_list(tag_list)
        found.should have(1).articles
        found.should include(welcome)
      end

      [ [chocolate, san_francisco], ["chocolate","san francisco"], "chocolate, san francisco" ].each do |tag_list|
        found = Article.find_all_by_tag_list(tag_list, 1)
        found.should have(2).articles
        found.should include(welcome, goodbye)
        found.first.should == welcome
      end
    end
  end

  describe "Article search" do
    scenario :blog

    it "should find posts and pages by matching query text to title" do
      found = Article.search("about")
      found.should include(articles(:about))
    end

    it "should find posts and pages by matching query text to body" do
      found = Article.search("teldra")
      found.should have(1).articles
      found.should include(articles(:new_release))

      found = Article.search("body")
      found.should have(3).articles
      found.should include(articles(:welcome, :update, :goodbye))
    end

    it "should find posts and pages by matching query text to extended" do
      found = Article.search("extended")
      found.should include(articles(:update))
    end

    it "should not find unpublished articles" do
      found = Article.search("body")
      found.should_not include(articles(:draft))
    end
  end
end
