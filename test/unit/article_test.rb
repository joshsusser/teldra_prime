require File.dirname(__FILE__) + '/../test_helper'

class ArticleTest < Test::Unit::TestCase
  context "Blog list" do
    scenario :blog

    should "find only posts in reverse chron order" do
      articles = Article.posts.recent
      assert articles.all? { |a| a.kind == Article::POST }
      assert_equal articles.sort {|a,b| b.published_at <=> a.published_at}, articles
    end
  
    should "find specified number of recent posts" do
      articles = Article.posts.recent
      assert_equal Article.find(:all).select { |a| a.post? && a.published_at? }.size, articles.size
      articles = Article.posts.limit(2)
      assert_equal 2, articles.size
    end
  end

  context "Finding posts with #find_post_by_date_and_slug" do
    scenario :blog

    should "find the post with slug published on given date" do
      update = articles(:update)
      post = Article.find_post_by_date_and_slug(*update.post_path_params)
      assert_equal update, post
    end

    should "raise error when called with bogus date" do
      update = articles(:update)
      assert_raise(ActiveRecord::RecordNotFound, "invalid date") do
        Article.find_post_by_date_and_slug("2007", "15", "45", update.slug)
      end
    end
  end

  context "Finding posts with #find_post_by_date_and_slug" do
    scenario :blog

    should "find the page with slug" do
      about = articles(:about)
      page = Article.find_page_by_slug(about.slug)
      assert_equal about, page
    end
  end

  context "Published post.post_path_params" do
    scenario :blog

    should "return array of params for creating url" do
      article = articles(:welcome)
      date = article.published_at
      assert_equal [date.year, date.month, date.mday, article.slug], article.post_path_params
    end

    should "raise when called on a non-post article" do
      page = articles(:about)
      assert_raise(ArgumentError) { page.post_path_params }
    end
  end

  context "Article with content" do
    scenario :basic

    should "return #content as body and extended" do
      article = articles(:extended_post)
      content = article.body + "\n\n" + article.extended
      assert_equal content, article.content
    end

    should "return #content body if extended is blank" do
      article = articles(:body_post)
      content = article.body
      assert_equal content, article.content
    end
  end

  context "Article comments" do
    scenario :blog

    should "allow comments for a Post article with open comments" do
      post = Article.new(:kind => Article::POST, :published_at => Time.now)

      tomorrow = 1.day.from_now
      next_year = 1.year.from_now

      post.comment_period = 7
      Time.stubs(:now).returns(tomorrow)
      assert post.allows_comments?

      post.comment_period = -1
      Time.stubs(:now).returns(next_year)
      assert post.allows_comments?
    end

    should "not allow comments for a Post article with closed comments" do
      post = Article.new(:kind => Article::POST, :published_at => Time.now)

      tomorrow = 1.day.from_now
      next_year = 1.year.from_now

      post.comment_period = 0
      Time.stubs(:now).returns(tomorrow)
      assert !post.allows_comments?

      post.comment_period = 30
      Time.stubs(:now).returns(next_year)
      assert !post.allows_comments?
    end

    should "never allow comments for a Page article" do
      page = articles(:about)
      assert !page.allows_comments?
    end
  end

  context "Article tags" do
    scenario :tags

    should "add tags when assigning to tag_list" do
      article = articles(:untagged)
      assert_equal [], article.tags

      article.tag_list = "test1"
      assert_equal "test1", article.tag_list
      assert_equal 1, Tagging.find_all_by_article_id(article.id).size
    
      article.tag_list = "test1, test1, test1"
      assert_equal "test1", article.tag_list
      assert_equal 1, Tagging.find_all_by_article_id(article.id).size
    
      article.tag_list = "test1, test2, test3"
      assert_equal "test1, test2, test3", article.tag_list
      assert_equal 3, Tagging.find_all_by_article_id(article.id).size
    
      article.tag_list = "test1, test3"
      assert_equal "test1, test3", article.tag_list
      assert_equal 2, Tagging.find_all_by_article_id(article.id).size
    
      article.tag_list = "testM, testZ, testA, testJ"
      assert_equal "testa, testj, testm, testz", article.tag_list
      assert_equal 4, Tagging.find_all_by_article_id(article.id).size
    
      article.tag_list = ""
      assert_equal "", article.tag_list
      assert_equal 0, Tagging.find_all_by_article_id(article.id).size
    end
  
    should "set tags on article that is a new record" do
      article = Article.create!(:user_id => 1, :title => "test", :slug => "test", :body => "test", :tag_list => "test, case")
      assert_equal "case, test", article.tag_list
    end

    should "find articles by list of tags" do
      welcome = articles(:welcome)
      goodbye = articles(:goodbye)
      san_francisco = tags(:san_francisco)
      chocolate = tags(:chocolate)

      [ [chocolate], ["chocolate"], "chocolate" ].each do |tag_list|
        found = Article.find_all_by_tag_list(tag_list)
        assert_equal 1, found.size
        assert found.include?(welcome)
      end
    
      [ [san_francisco], ["san francisco"], "san francisco" ].each do |tag_list|
        found = Article.find_all_by_tag_list(tag_list)
        assert_equal 2, found.size
        assert found.include?(welcome)
        assert found.include?(goodbye)
      end
    
      [ [chocolate, san_francisco], ["chocolate","san francisco"], "chocolate, san francisco" ].each do |tag_list|
        found = Article.find_all_by_tag_list(tag_list)
        assert_equal 1, found.size
        assert found.include?(welcome)
      end

      [ [chocolate, san_francisco], ["chocolate","san francisco"], "chocolate, san francisco" ].each do |tag_list|
        found = Article.find_all_by_tag_list(tag_list, 1)
        assert_equal 2, found.size
        assert found.include?(welcome)
        assert found.include?(goodbye)
        assert_equal found.first, welcome
      end
    end
  end
  
  context "Article search" do
    scenario :blog
  
    should "find posts and pages by matching query text to title" do
      found = Article.search("about")
      assert found.include?(articles(:about))
    end

    should "find posts and pages by matching query text to body" do
      found = Article.search("teldra")
      assert_equal 1, found.size
      assert found.include?(articles(:new_release))

      found = Article.search("body")
      assert found.include?(articles(:welcome))
      assert found.include?(articles(:update))
      assert found.include?(articles(:goodbye))
    end

    should "find posts and pages by matching query text to extended" do
      found = Article.search("extended")
      assert found.include?(articles(:update))
    end

    should "not find unpublished articles" do
      found = Article.search("body")
      assert !found.include?(articles(:draft))
    end
  end
end