require 'capybara_helper'

describe 'visiting /Help' do
  describe 'when the user is not signed in' do
    before do
      visit '/'
      click_on(I18n.t('layouts.unsigned_user_nav.help'))
    end

    it 'can access the Help page' do
      expect(page).to have_content(I18n.t('help.heading'))
    end

    it "can not see the 'Create form' button" do
      expect(page).to_not have_link(I18n.t('services.index.new_service'))
    end
  end

  context 'with a signed in user' do
    let(:user) { User.find_or_create_by(name: 'test user', email: 'test@example.justice.gov.uk') }

    before do
      login_as!(user)
      click_on(I18n.t('layouts.unsigned_user_nav.help'))
    end

    it 'can access the Help page' do
      expect(page).to have_content(I18n.t('help.heading'))
    end

    it "can see the 'Create form' button" do
      expect(page).to have_link(I18n.t('services.index.new_service'))
    end
    it "can visit the 'Create form' page" do
      within('#content') do
        click_link(I18n.t('services.index.new_service'))
      end
      expect(page).to have_content(I18n.t('services.new.lede_html'))
    end
  end
end
