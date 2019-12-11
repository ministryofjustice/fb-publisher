def login_as!(email)
  visit '/auth/developer'
  fill_in :email, with: email
  click_on 'Sign In'
end

def logout!
  click_on 'Sign out'
end
