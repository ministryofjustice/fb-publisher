def auth0_userinfo(user=nil)
  OmniAuth::AuthHash.new( {
    "provider"=>"auth0",
    "uid"=>"google-oauth2|012345678900123456789",
    "info"=>{
      "name"=> user.try(:name) || "John Smith",
      "email"=> user.try(:email) || "john.smith@test-only.justice.gov.uk"
    }
  } )
end

def stub_auth0_userinfo(info)
  OmniAuth.config.test_mode = true
  OmniAuth.config.add_mock(:auth0, auth0_userinfo(user))
end

def stub_cookie_variable!(name, value)
  cookie_jar = Capybara.current_session.driver.browser.rack_mock_session.cookie_jar
  cookie_jar[:"stub_#{name.to_s}"] = value
end

def clear_session!
  stub_cookie_variable!(:user_id, nil)
end

def login_as!(user)
  stub_auth0_userinfo(user)
  visit '/'
  click_link(I18n.t(:sign_in, scope: [:layouts, :unsigned_user_nav]))
  #visit auth0_callback_path
end
