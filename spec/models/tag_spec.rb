require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Tag parsing" do
  it "should parse list of tags" do
    Tag.parse("").should be_empty
    Tag.parse("a, b, c").should == %w(a b c)
    Tag.parse("a, b, c, a, b, a").should == %w(a b c)
    Tag.parse("  O'NE , two, - , // thrEE,, 1337").should == %w(one two three 1337)
  end
end

describe Tag do
  scenario :tags

  describe "#find_all_popular" do
    it "should return all tags sorted descending by number of taggings" do
      tags = Tag.find_all_popular
      tags.should have(Tag.count).items
      in_order = true
      0.upto(tags.size - 2) { |i| in_order &&= (tags[i].taggings_count >= tags[i+1].taggings_count) }
      in_order.should be_true
    end

    it "should not return tags with no taggings" do
      lonely = Tag.create!(:name => "lonely")
      tags = Tag.find_all_popular
      tags.should_not include(lonely)
      tags.all? { |t| t.taggings_count > 0 }.should be_true
    end
  end

  describe "posts.recent" do
    it "should return the tag's posts in revers chron order" do
      sf = tags(:san_francisco)
      posts = sf.articles.recent
      posts.should have(sf.articles.size).articles
      posts.should be_sorted { |a,b| b.published_at <=> a.published_at }
    end
  end
end
