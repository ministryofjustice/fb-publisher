

def auth0_userinfo
  {
    "provider"=>"auth0",
    "uid"=>"google-oauth2|012345678900123456789",
    "info"=>{
      "name"=>"John Smith",
      "email"=>"john.smith@test-only.justice.gov.uk"
    }
  }
end

def stub_cookie_variable!(name, value)
  cookie_jar = Capybara.current_session.driver.browser.current_session\
                       .instance_variable_get(:@rack_mock_session)\
                       .cookie_jar
  cookie_jar[:"stub_#{name.to_s}"] = value
end

def clear_session!
  stub_cookie_variable!(:user_id, nil)
end

def login_as!(user)
  if Capybara.current_driver == :webkit
    page.driver.browser.set_cookie("stub_user_id=#{user.id}; path=/; domain=127.0.0.1")
  else
    stub_cookie_variable!(:user_id, user.id)
  end
end
