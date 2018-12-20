require 'capybara_helper'

describe 'visiting /teams' do
  context 'as a logged in user' do
    let(:user) { User.find_or_create_by(name: 'test user', email: 'test@example.justice.gov.uk') }
    before do
      login_as!(user)
    end

    context 'accessing a team via url that you did not create nor are not a member of' do
      let(:other_user) {User.create(name: 'other user', email: 'other_user@example.justice.gov.uk') }
      let(:team) do
        Team.create!(name: 'Formbuilder', created_by_user: other_user)
      end
      before do
        visit "/teams/#{team.slug}"
      end

      it 'shows flash not authorised error message' do
        expect(page).to have_content(I18n.t(:pundit_not_authorized_error, scope: [:errors, :pundit]))
      end
    end

    context 'attempting to access a non-existing team via url' do
      before do
        visit "/teams/not-a-real-team"
      end

      it 'shows flash not found error message' do
        expect(page).to have_content(I18n.t(:pundit_not_defined_error, scope: [:errors, :pundit]))
      end
    end
  end
end
