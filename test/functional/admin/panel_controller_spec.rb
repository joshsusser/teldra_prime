require File.dirname(__FILE__) + '/../../test_helper'

class Admin::PanelControllerTest < ActionController::TestCase
  scenario :blog

  context "when logged out" do
    setup { logout }
    context "index" do
      setup { get :index }
      should_redirect_to "login_url"
    end
  end

  context "when logged in as admin" do
    setup { login_as :admin }
    context "index" do
      setup { get :index }
      should_render_template "index"
    end
  end
end
