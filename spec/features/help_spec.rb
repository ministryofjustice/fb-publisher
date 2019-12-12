require 'capybara_helper'

describe '/help' do
  describe 'when the user is not signed in' do
    before do
      visit '/'
      click_on 'Help'
    end

    it 'can access the Help page' do
      expect(page).to have_content('Help getting started')
      expect(page).to_not have_link('Create form')
    end
  end

  context 'with a signed in user' do
    let(:email) { 'test@example.justice.gov.uk' }

    before do
      login_as!(email)
      click_on 'Help'
    end

    it 'can access the Help page' do
      expect(page).to have_content('Help getting started')
      expect(page).to have_link('Create form')
    end

    it "can visit the 'Create form' page" do
      within('#content') do
        click_link('Create form')
      end

      expect(page.current_url).to match(/\/services\/new$/)
    end
  end
end
