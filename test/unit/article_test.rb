require File.dirname(__FILE__) + '/../test_helper'

class ArticleTest < ActiveSupport::TestCase
  class BasicTest < ArticleTest
    scenario :basic

    def test_should_return_content_as_body_and_extended
      article = articles(:extended_post)
      content = article.body + "\n\n" + article.extended
      assert_equal content, article.content
    end

    def test_should_return_content_body_if_extended_is_blank
      article = articles(:body_post)
      content = article.body
      assert_equal content, article.content
    end
  end

  class BlogTest < ArticleTest
    scenario :blog

    # list
    def test_should_find_only_posts_in_reverse_chron_order
      articles = Article.posts.recent
      assert articles.size > 0
      assert articles.all? { |a| a.kind == Article::POST }
      assert_sorted(articles) { |a,b| b.published_at <=> a.published_at }
    end

    def test_should_find_specified_number_of_recent_posts
      articles = Article.posts.recent
      assert_equal Article.find(:all).select { |a| a.post? && a.published_at? }.size, articles.size
      articles = Article.posts.limit(2)
      assert_equal 2, articles.size
    end

    # find_post_by_date_and_slug
    def test_should_find_the_post_with_slug_published_on_given_date
      update = articles(:update)
      post = Article.find_post_by_date_and_slug(*update.post_path_params)
      assert_equal update, post
    end

    def test_should_raise_error_when_called_with_bogus_date
      update = articles(:update)
      assert_raise(ActiveRecord::RecordNotFound, "invalid date") do
        Article.find_post_by_date_and_slug("2007", "15", "45", update.slug)
      end
    end

    # find_page_by_slug
    def test_should_find_the_page_with_slug
      about = articles(:about)
      page = Article.find_page_by_slug(about.slug)
      assert_equal about, page
    end

    # post_path_params
    def test_should_return_array_of_params_for_creating_url
      article = articles(:welcome)
      date = article.published_at
      assert_equal [date.year, date.month, date.mday, article.slug], article.post_path_params
    end

    def test_should_raise_when_called_on_a_non_post_article
      page = articles(:about)
      assert_raise(ArgumentError) { page.post_path_params }
    end

    # comments
    def should_allow_comments_for_a_post_article_with_open_comments
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

    def should_not_allow_comments_for_a_post_article_with_closed_comments
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

    def should_never_allow_comments_for_a_Page_article
      page = articles(:about)
      assert !page.allows_comments?
    end

    # search
    def should_find_posts_and_pages_by_matching_query_text_to_title
      found = Article.search("about")
      assert found.include?(articles(:about))
    end

    def should_find_posts_and_pages_by_matching_query_text_to_body
      found = Article.search("teldra")
      assert_equal 1, found.size
      assert found.include?(articles(:new_release))

      found = Article.search("body")
      assert found.include?(articles(:welcome))
      assert found.include?(articles(:update))
      assert found.include?(articles(:goodbye))
    end

    def should_find_posts_and_pages_by_matching_query_text_to_extended
      found = Article.search("extended")
      assert found.include?(articles(:update))
    end

    def should_not_find_unpublished_articles
      found = Article.search("body")
      assert !found.include?(articles(:draft))
    end
  end

  class TagsTest < ArticleTest
    scenario :tags

    def should_add_tags_when_assigning_to_tag_list
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

    def should_set_tags_on_article_that_is_a_new_record
      article = Article.create!(:user_id => 1, :title => "test", :slug => "test", :body => "test", :tag_list => "test, case")
      assert_equal "case, test", article.tag_list
    end

    def should_find_articles_by_list_of_tags
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
end
