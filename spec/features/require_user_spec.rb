
require 'capybara_helper'

describe 'visiting the home page' do
  before do
    visit '/'
  end
  context 'when not logged in' do
    before do
      clear_session!
    end

    it 'shows a link to login' do
      expect(page).to have_link('Login')
    end
  end

  context 'as a logged in user' do
    let(:user){ instance_double(User, id: 'abc123') }
    before do
      login_as!(user)
    end

    it 'does not show a link to login' do
      expect(page).to have_link('Login')
    end
  end
end


describe 'visiting a page that requires a current user' do
  before do
    visit '/'
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
    let(:user){ instance_double(User, id: 'abc123') }
    before do
      login_as!(user)
    end

    it 'does not redirect to home' do
      expect(page.current_url).to eq(root_url)
    end
  end
end
