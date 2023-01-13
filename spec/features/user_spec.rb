require 'capybara_helper'

describe 'View / Profile' do
  describe 'set user timezone' do
    describe 'as a logged in user' do
      let(:user) { User.find_or_create_by(name: 'test user', email: 'test@example.justice.gov.uk') }

      before do
        allow_any_instance_of(ApplicationController).to receive(:public_user?).and_return(false)
        login_as!(user)
        visit 'user/edit'
      end

      it 'displays my current timezone' do
        expect(page).to have_content(I18n.t(:lede_html, scope: [:users, :edit], timezone: user.timezone))
      end

      context 'I can select a timezone' do
        it 'successfully renders timezone list' do
          expect(page).to have_select('user_timezone')
        end
      end

      context 'when selecting a timezone & submitting the form' do
        before do
          select 'Paris', from: 'user_timezone'
          click_button(I18n.t('users.form.submit'))
        end
        it 'users timezone successfully saved' do
          expect(page).to have_content(I18n.t('users.update.success'))
          expect(page).to have_content(I18n.t(:lede_html, scope: [:users, :edit], timezone: 'Paris'))
        end
      end
    end

    describe 'as an unauthorised user' do
      before do
        visit 'user/edit'
      end
      it 'does not render user edit page' do
        expect(page).to have_content(I18n.t('home.show.heading'))
      end
    end
  end
end
