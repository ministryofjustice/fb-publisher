require 'capybara_helper'

describe 'visiting /teams' do
  context 'as a logged in user' do
    let(:user) { User.find_or_create_by(name: 'test user', email: 'test@example.justice.gov.uk') }
    before do
      allow_any_instance_of(ApplicationController).to receive(:public_user?).and_return(false)
      login_as!(user)
    end

    describe 'access team show page' do
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

    describe 'viewing team index page' do
      context 'when there are more than 10 teams' do
        before do
          16.times { |i| create_team(i) }
          visit '/teams'
        end

        it 'enables link to the next page' do
          expect(page).to have_link('Next')
        end

        context 'if not on the first page' do
          before do
            click_link('Next')
          end
          it 'enables link to the previous page' do
            expect(page).to have_link('Prev')
          end
        end
      end

      context 'when there are less than 10 teams' do
        before do
          9.times { |i| create_team(i) }
          visit '/teams'
        end

        it 'does not enable a link to the next page' do
          expect(page).to_not have_link('Next')
        end

        it 'does not enable link to the previous page' do
          expect(page).to_not have_link('Prev')
        end
      end

      def create_team(number)
        Team.create(name: 'Team ' + number.to_s, created_by_user: user)
      end
    end
  end
end
