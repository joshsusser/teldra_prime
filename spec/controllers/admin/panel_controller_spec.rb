require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Admin::PanelController do
  scenario :blog

  describe "when logged out" do
    before do
      logout
    end
    it "should redirect index to login" do
      get :index
      response.should redirect_to(login_url)
    end
  end

  describe "when logged in" do
    before do
      login_as :admin
    end
    it "should show index" do
      get :index
      response.should be_success
    end
  end
end
