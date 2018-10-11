require 'capybara_helper'

describe 'visiting / service permissions' do
  let(:user) { User.find_or_create_by(name: 'test user', email: 'test@example.justice.gov.uk') }
  let(:service) do
    Service.create!(id: 'fed456', name: 'My New Service', slug: 'my-new-service',
                    git_repo_url: 'https://github.com/some-organisation/some-repo.git',
                    created_by_user: user)
  end
  context 'as a logged in user' do
    before do
      login_as!(user)
    end

    describe 'creating a new team' do
      describe 'when no teams exists' do
        context 'user tries to create a team without a team name' do
          before do
            visit "/services/#{service.slug}/permissions"
            click_button(I18n.t('services.permissions.form.submit'))
          end
          it 'displays an error message' do
            expect(page).to have_content(I18n.t(:active_record_record_not_found,
                                                scope: [:services, :permissions, :create, :errors]))
          end
        end
        context 'user adds a new team' do
          before do
            visit "/services/#{service.slug}/permissions"
            fill_in('permission[new_team]', with: 'Team Blue')
            click_button(I18n.t('services.permissions.form.submit'))
          end
          it 'grants permission to newly created team' do
            expect(page).to have_link('Team Blue', href: '/teams/team-blue')
          end
          it 'displays a link to remove permissions to newly created team' do
            expect(page).to have_button(I18n.t('services.permissions.permission.delete'))
          end
          it 'displays a success message' do
            expect(page).to have_content(I18n.t(:success, scope: [:services, :permissions, :create]))
          end
        end
      end

      context 'when there are existing teams' do
        before do
          Team.create!(id: 1234, name: 'A Team', slug: 'a-team', created_by_user: user)
          Team.create!(id: 5678, name: '123 Team', slug: '123-team', created_by_user: user)
          visit "/services/#{service.slug}/permissions"
        end

        context 'when both team name is selected and new team entered' do
          before do
            fill_in('permission[new_team]', with: 'Team Blue')
            click_button(I18n.t('services.permissions.form.submit'))
          end
          it 'grants permission to the newly created team' do
            expect(page).to have_link('Team Blue', href: '/teams/team-blue')
          end
          it 'displays a success message' do
            expect(page).to have_content(I18n.t(:success, scope: [:services, :permissions, :create]))
          end
        end

        context 'when user enters a duplicate team name' do
          before do
            fill_in('permission[new_team]', with: '123 Team')
            click_button(I18n.t('services.permissions.form.submit'))
          end
          it 'displays an error message' do
            expect(page).to have_content(I18n.t(:active_record_record_invalid,
                                                scope: [:services, :permissions, :create, :errors]))
          end
        end

        context 'when only team name selected' do
          before do
            select 'A Team', from: 'permission[team_id]'
            click_button(I18n.t('services.permissions.form.submit'))
          end
          it 'grants permission to the existing team' do
            expect(page).to have_link('A Team', href: '/teams/a-team')
          end
          it 'displays a success message' do
            expect(page).to have_content(I18n.t(:success, scope: [:services, :permissions, :create]))
          end
        end

        context 'when a permission could not be added for a team' do
          let(:other_user) do
            User.find_or_create_by(name: 'Another test user', email: 'another_test@example.justice.gov.uk')
          end
          let(:a_team) { Team.find_by_name('A Team') }

          before do
            visit "/services/#{service.slug}/permissions"
            select 'A Team', from: 'permission[team_id]'
          end

          context 'when there is a Pundit authorisation error' do
            before do
              a_team.created_by_user = other_user
              a_team.save
              click_button(I18n.t('services.permissions.form.submit'))
            end
            it 'displays the error message' do
              expect(page).to have_content(I18n.t(:pundit_not_authorized_error,
                                                  scope: [:services, :permissions, :create, :errors]))
            end
          end
          context 'when there is a no record error' do
            before do
              a_team.delete
              a_team.save
            end
            it 'displays the error message' do
              click_button(I18n.t('services.permissions.form.submit'))
              expect(page).to have_content(I18n.t(:name_error,
                                                  scope: [:services, :permissions, :create, :errors]))
            end
          end
        end
      end
    end
  end
end