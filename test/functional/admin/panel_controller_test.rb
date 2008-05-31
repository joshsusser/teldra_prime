require File.dirname(__FILE__) + '/../../test_helper'

class Admin::PanelControllerTest < ActionController::TestCase
  scenario :blog

  def test_should_authenticate
    logout
    get :index
    assert_redirected_to login_url()
  end

  def test_should_show_panel
    login_as :admin
    get :index
    assert_response :success
    assert_template "index"
  end
end
