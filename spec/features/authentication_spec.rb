
require 'capybara_helper'

describe 'visiting the home page' do
  before do
    visit '/'
  end
  context 'when not logged in' do
    before do
      session.reset!
    end

    it 'shows a link to login' do
      expect(page).to have_link('Login')
    end

  end

  context 'as a logged in user' do
    before do
      stub_login!
    end

    it 'does not show a link to login' do
      expect(page).to have_link('Login')
    end
  end
end
