require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Comment do
  scenario :blog
  
  describe "#presentation_class" do
    it "should show presentation_class for guest" do
      comment = comments(:stranger_welcome)
      comment.presentation_class.should == "by-guest"
    end

    it "should show presentation_class for author" do
      comment = comments(:admin_welcome)
      comment.presentation_class.should == "by-author"
    end
  end

  describe "#author_link" do
    it "should show name with link for comment with author URL" do
      comment = comments(:stranger_welcome)
      Regexp.new(Regexp.escape(comment.author_name))
      comment.author_link.should =~ Regexp.new(Regexp.escape(comment.author_url))
    end

    it "should show name with no link for comment with no author URL" do
      comment = comments(:stalker_welcome)
      comment.author_link.should =~ Regexp.new(Regexp.escape(comment.author_name))
      comment.author_link.should_not =~ %r{http://}
    end
  end
end
