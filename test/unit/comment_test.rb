require File.dirname(__FILE__) + '/../test_helper'

class CommentTest < ActiveSupport::TestCase
  scenario :blog

  # presentation_class
  def test_should_show_presentation_class_for_guest
    comment = comments(:stranger_welcome)
    assert_equal "by-guest", comment.presentation_class
  end

  def test_should_show_presentation_class_for_author
    comment = comments(:admin_welcome)
    assert_equal "by-author", comment.presentation_class
  end

  # author_link
  def test_should_show_name_with_link_for_comment_with_author_url
    comment = comments(:stranger_welcome)
    assert_match Regexp.new(Regexp.escape(comment.author_name)), comment.author_link
    assert_match Regexp.new(Regexp.escape(comment.author_url)), comment.author_link
  end

  def test_should_show_name_with_no_link_for_comment_with_no_author_url
    comment = comments(:stalker_welcome)
    assert_match Regexp.new(Regexp.escape(comment.author_name)), comment.author_link
    assert_no_match %r{http://}, comment.author_link
  end
end
