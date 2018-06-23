require 'capybara_helper'

describe 'logging in as a particular user' do
  before do
    clear_session!
  end

  context 'who does not have a valid email' do
    let(:user){ User.new(name: 'invalid user', email: 'user@example.com') }

    it 'redirects me to signup_not_allowed' do
      login_as!(user)
      expect(page.current_url).to eq(signup_not_allowed_url)
    end

    it 'tells me I am not allowed to sign up with that email' do
      login_as!(user)
      expect(page).to have_content("You can't sign up with that email address")
    end

    it 'tells me what my email address must be like' do
      login_as!(user)
      expect(page).to have_content("you must use an email address that ends in justice.gov.uk")
    end
  end

  context 'who has a valid email' do
    let(:user){ User.new(name: 'new user', email: 'user@justice.gov.uk') }

    context 'but does not already exist' do
      it 'redirects me to the welcome page' do
        login_as!(user)
        expect(page.current_url).to eq(welcome_url)
      end

      it 'shows me a welcome message with my name' do
        login_as!(user)
        expect(page).to have_content("Thanks for joining us, new user!")
      end
    end

    context 'and already exists' do
      before do
        user.save!
        user.identities << Identity.new(provider: 'auth0', uid: 'google-oauth2|012345678900123456789', email: user.email, name: user.name)
      end

      it 'redirects me to the dashboard' do
        login_as!(user)
        expect(page.current_url).to eq(dashboard_url)
      end

      it 'shows me a welcome back message with my name' do
        login_as!(user)
        expect(page).to have_content("Welcome back, #{user.name}!")
      end
    end
  end
end
