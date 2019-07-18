require 'capybara_helper'

describe 'signing out' do
  let(:user){ User.new(name: 'new user', email: 'user@justice.gov.uk') }
  before do
    clear_session!
  end

  context 'when logged in' do
    before do
      login_as!(user)
    end

    it 'shows me a Sign Out link' do
      expect(page).to have_button("Sign out")
    end

    context 'clicking the Sign Out link' do
      before do
        page.find("input[value='Sign out']").click()
      end

      it 'redirects me to the home page' do
        expect(page.current_url).to eq(root_url)
      end

      it 'shows a button to login' do
        expect(page).to have_link(I18n.t(:sign_in, scope: [:layouts, :unsigned_user_nav]))
      end
    end
  end
end
