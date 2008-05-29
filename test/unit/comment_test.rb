require File.dirname(__FILE__) + '/../test_helper'

class CommentTest < Test::Unit::TestCase
  scenario :blog

  should_belong_to :user
  should_require_attributes :body
  
  context "#presentation_class" do
    should "show presentation_class for guest" do
      comment = comments(:stranger_welcome)
      assert_equal "by-guest", comment.presentation_class
    end

    should "show presentation_class for author" do
      comment = comments(:admin_welcome)
      assert_equal "by-author", comment.presentation_class
    end
  end

  context "#author_link" do
    should "show name with link for comment with author URL" do
      comment = comments(:stranger_welcome)
      assert_match Regexp.new(Regexp.escape(comment.author_name)), comment.author_link
      assert_match Regexp.new(Regexp.escape(comment.author_url)), comment.author_link
    end

    should "show name with no link for comment with no author URL" do
      comment = comments(:stalker_welcome)
      assert_match Regexp.new(Regexp.escape(comment.author_name)), comment.author_link
      assert_no_match %r{http://}, comment.author_link
    end
  end
end
