require 'capybara_helper'

describe 'logging in as a particular user' do
  context 'who does not have a valid email' do
    let(:email){ 'user@example.com' }

    it 'does not allow sign up' do
      login_as!(email)

      expect(page.current_url).to match(/\/signup_not_allowed$/)
      expect(page).to have_content("You can't sign up with that email address")
      expect(page).to have_content("you must use an email address that ends in justice.gov.uk")
    end
  end

  context 'who has a valid email' do
    let(:email){ 'user@justice.gov.uk' }

    context 'but does not already exist' do
      it 'redirects me to the welcome page and joining message' do
        login_as!(email)
        expect(page.current_url).to match(/\/welcome$/)
        expect(page).to have_content('Thanks for joining us')
      end
    end

    context 'and already exists' do
      before do
        login_as!(email)
        logout!
      end

      it 'redirects me to the services page with welcome back' do
        login_as!(email)
        expect(page.current_url).to match(/\/services$/)
        expect(page).to have_content('Welcome back')
      end
    end
  end
end
