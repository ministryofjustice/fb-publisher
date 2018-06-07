

def valid_session
  {
    userinfo: {
      'uid' => 'userinfouid-abc123',
      'email' => 'nil'
    }
  }
end

def stub_login!
  controller.session[:userinfo] = valid_session[:userinfo]
end
