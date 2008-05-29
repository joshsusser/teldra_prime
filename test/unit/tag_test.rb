require File.dirname(__FILE__) + '/../test_helper'

class TagTest < Test::Unit::TestCase
  scenario :tags

  context "parsing" do
    should "parse list of tags" do
      assert_equal [], Tag.parse("")
      assert_equal %w(a b c), Tag.parse("a, b, c")
      assert_equal %w(a b c), Tag.parse("a, b, c, a, b, a")
      assert_equal %w(one two three 1337), Tag.parse("  O'NE , two, - , // thrEE,, 1337")
    end
  end

  context "find_all_popular" do
    should "return all tags sorted descending by number of taggings" do
      tags = Tag.find_all_popular
      assert_equal Tag.count, tags.size
      in_order = true
      0.upto(tags.size - 2) { |i| in_order &&= (tags[i].taggings_count >= tags[i+1].taggings_count) }
      assert in_order
    end

    should "not return tags with no taggings" do
      lonely = Tag.create!(:name => "lonely")
      tags = Tag.find_all_popular
      assert !tags.include?(lonely)
      assert tags.all? { |t| t.taggings_count > 0 }
    end
  end

  context "posts.recent" do
    should "return the tag's posts in revers chron order" do
      sf = tags(:san_francisco)
      posts = sf.articles.recent
      assert_equal sf.articles.size, posts.size
      assert_equal posts.sort {|a,b| b.published_at <=> a.published_at}, posts
    end
  end
end
