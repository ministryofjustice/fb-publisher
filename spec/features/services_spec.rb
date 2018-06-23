require 'capybara_helper'

describe 'visiting /services' do
  context 'as a logged in user' do
    let(:user){ instance_double(User, id: 'abc123') }
    before do
      login_as!(user)
    end

    it 'shows a list of my services' do
      visit '/services'
      expect(page).to have_content('Your Services')
    end
  end
end
