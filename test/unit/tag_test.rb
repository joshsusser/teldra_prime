require File.dirname(__FILE__) + '/../test_helper'

class TagTest < ActiveSupport::TestCase
  scenario :tags

  # parsing
  def test_should_parse_list_of_tags
    assert_equal [], Tag.parse("")
    assert_equal %w(a b c), Tag.parse("a, b, c")
    assert_equal %w(a b c), Tag.parse("a, b, c, a, b, a")
    assert_equal %w(one two three 1337), Tag.parse("  O'NE , two, - , // thrEE,, 1337")
  end

  # find_all_popular
  def test_should_return_all_tags_sorted_descending_by_number_of_taggings
    tags = Tag.find_all_popular
    assert_equal Tag.count, tags.size
    in_order = true
    0.upto(tags.size - 2) { |i| in_order &&= (tags[i].taggings_count >= tags[i+1].taggings_count) }
    assert in_order
  end

  def test_should_not_return_tags_with_no_taggings
    lonely = Tag.create!(:name => "lonely")
    tags = Tag.find_all_popular
    assert !tags.include?(lonely)
    assert tags.all? { |t| t.taggings_count > 0 }
  end

  # Tag.posts.recent
  def test_should_return_the_tag_s_posts_in_revers_chron_order
    sf = tags(:san_francisco)
    posts = sf.articles.recent
    assert_equal sf.articles.size, posts.size
    assert_sorted(posts) { |a,b| b.published_at <=> a.published_at }
  end
end
