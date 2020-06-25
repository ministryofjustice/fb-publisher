
require 'capybara_helper'

describe 'visiting the home page' do
  before do
    visit '/'
  end
  context 'when not logged in' do
    before do
      clear_session!
    end

    it 'shows a button to login' do
      expect(page).to have_link(I18n.t(:sign_in, scope: [:layouts, :unsigned_user_nav]))
    end

    it 'shows a link to sign in' do
      expect(page).to have_link(I18n.t(:sign_in, scope: [:layouts, :unsigned_user_nav]))
    end
  end

  context 'as a logged in user' do
    let(:user){ instance_double(User, id: 'abc123') }
    before do
      login_as!(user)
    end

    it 'does not show a link to login' do
      expect(page).to_not have_link(I18n.t(:link_text, scope: [:home, :login]))
    end

    it 'does not show a link to sign in' do
      expect(page).to_not have_link(I18n.t(:sign_in, scope: [:layouts, :unsigned_user_nav]))
    end

    it "shows a link to 'create form'" do
      expect(page).to have_link(I18n.t('layouts.user_nav.create_form'))
    end
  end
end


describe 'visiting a page that requires a current user' do
  before do
    visit '/services'
  end
  context 'when not logged in' do
    before do
      clear_session!
    end

    it 'redirects to home' do
      expect(page.current_url).to eq(root_url)
    end
  end

  context 'as a logged in user' do
    let(:user){ instance_double(User, id: 'abc123', name: 'user name', email: 'user@justice.gov.uk') }
    before do
      login_as!(user)
    end

    context 'with a session that has not expired' do
      it 'does not redirect to home' do
        expect(page.current_url).to_not eq(root_url)
      end
    end
  end
end
