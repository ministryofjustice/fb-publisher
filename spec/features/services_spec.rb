require 'capybara_helper'

describe 'visiting /services' do
  before do
    allow_any_instance_of(ApplicationController).to receive(:public_user?).and_return(false)
    allow(DeploymentService).to receive(:url_for).and_return('url.test')
  end

  context 'as a logged in user' do
    let(:user) { User.find_or_create_by(name: 'test user', email: 'test@example.justice.gov.uk') }
    before do
      login_as!(user)
    end

    it 'shows a list of my service forms' do
      visit '/services'
      within('h1') do
        expect(page).to have_content(I18n.t(:heading, scope: [:services, :index]))
      end
    end

    it 'has a link to create a new service form' do
      visit '/services'
      within('#content') do
        expect(page).to have_link(I18n.t(:new_service, scope: [:services, :index]))
      end
    end

    describe 'clicking "Create form"' do
      before do
        visit '/services'
        within('#content') do
          click_link(I18n.t(:new_service, scope: [:services, :index]))
        end
      end

      it "shows the 'Create form' page" do
        within('h1') do
          expect(page).to have_content(I18n.t(:heading, scope: [:services, :new]))
        end
      end
    end

    describe 'filtering service list' do
      let(:another_user) { User.find_or_create_by(name: 'another user', email: 'another@example.justice.gov.uk') }
      let(:admin_user) { User.find_or_create_by(name: 'admin user', email: 'admin@example.justice.gov.uk') }
      let(:admin_team) { Team.create!(name: 'Super Admin', created_by_user_id: admin_user.id, super_admin: true) }

      before do
        TeamMember.create!(user_id: admin_user.id, team_id: admin_team.id, created_by_user_id: user.id)
        named_service('Test Service', user)
        named_service('Leavers Service', user)
        named_service('Joiners Service', user)
        named_service('IOJ Form', another_user)
        named_service('Flexible Working Service', another_user)
        named_service('Admin Form', admin_user)
      end

      describe 'when no filtering is applied' do
        before do
          visit '/services'
        end

        it 'list includes Test Service' do
          within('table') do
            expect(page).to have_content('Test Service')
          end
        end

        it 'list includes Leavers Service' do
          within('table') do
            expect(page).to have_content('Leavers Service')
          end
        end

        it 'list includes Joiners Service' do
          within('table') do
            expect(page).to have_content('Joiners Service')
          end
        end

        it 'list does not include IOJ Service' do
          within('table') do
            expect(page).not_to have_content('IOJ Service')
          end
        end

        it 'list does not include Admin Service' do
          expect(page).not_to have_content('Admin Service')
        end
      end

      describe 'when filtering is applied that matches a form available to the user' do
        before do
          visit '/services?utf8=&query=ers&commit=Filter'
        end

        it 'list includes Leavers Service' do
          within('table') do
            expect(page).to have_content('Leavers Service')
          end
        end

        it 'list includes Joiners Service' do
          within('table') do
            expect(page).to have_content('Joiners Service')
          end
        end

        it 'list does not includes Test Service' do
          within('table') do
            expect(page).not_to have_content('Test Service')
          end
        end
      end

      describe 'when filtering is applied that does not match a form available to the user' do
        before do
          visit '/services?utf8=&query=working&commit=Filter'
        end

        it 'list does not includes Flexible Working Service' do
          within('table') do
            expect(page).not_to have_content('Flexible Working Service')
          end
        end

        it 'list includes ALL available forms user is able to access' do
          expect(page).to have_content('Test Service')
          expect(page).to have_content('Joiners Service')
          expect(page).to have_content('Leavers Service')
        end
      end

      def named_service(name, user)
        Service.create(name: name,
                       git_repo_url: 'https://github.com/ministryofjustice/fb-sample-json.git',
                       created_by_user: user)
      end
    end

    describe 'viewing service list' do
      context 'when there are more than 10 services' do
        before do
          14.times { |i| create_service(i) }
          visit '/services'
        end

        it 'enables link to next page' do
          expect(page).to have_link('Next')
        end

        context 'if not on the first page' do
          before do
            click_link('Next')
          end
          it 'enables link to previous page' do
            expect(page).to have_link('Prev')
          end
        end
      end

      context 'when there are less than 10 services' do
        before do
          9.times { |i| create_service(i) }
          visit '/services'
        end

        it 'does not enable a link to the next page' do
          expect(page).to_not have_link('Next')
        end

        it 'does not enable link to the previous page' do
          expect(page).to_not have_link('Prev')
        end
      end

      def create_service(number)
        Service.create(name: 'Service ' + number.to_s,
                       git_repo_url: 'https://github.com/ministryofjustice/fb-sample-json.git',
                       created_by_user: user)
      end
    end

    describe "filling in the 'Create form'" do
      before do
        visit new_service_path
      end

      context 'when I fill in the Service name' do
        before do
          fill_in(I18n.t(:name, scope: [:helpers, :label, :service]), with: name)
        end
        context 'with a valid name' do
          let(:name) { 'My new service' }

          context 'and click Create form' do
            before do
              click_button(I18n.t(:submit, scope: [:services, :new, :form]))
            end

            it 'does not submit the form' do
              expect(page).to have_content(I18n.t(:errors_intro, scope: [:shared]))
            end
          end

          context 'and fill in the git repo url' do
            before do
              fill_in(I18n.t(:git_repo_url, scope: [:helpers, :label, :service]), with: url)
            end
            context 'with a valid https git repo url' do
              let(:url) { 'https://git.example.com/repo.git' }

              context 'and click Create form' do
                before do
                  within('#content') do
                    click_on(I18n.t(:submit, scope: [:services, :new, :form]))
                  end
                end

                it 'shows the deployment environment names' do
                  expect(page).to have_content('Test')
                  expect(page).to have_content('Live')
                end

                it 'shows me a notice saying it was created successfully' do
                  expect(page).to have_content(I18n.t(:success, scope: [:services, :create], service: name))
                end
              end
            end
          end
        end
      end
    end

    context 'with an existing service' do
      let(:service_name) { 'My First Service' }
      before do
        visit '/services/new'
        fill_in(I18n.t(:name, scope: [:helpers, :label, :service]), with: service_name)
        fill_in(I18n.t(:git_repo_url, scope: [:helpers, :label, :service]), with: 'https://repo.url/repo.git')
        within('#content') do
          click_on(I18n.t(:submit, scope: [:services, :new, :form]))
        end
      end

      describe 'Deleting a service', js: true do
        before do
          visit '/services'
          accept_confirm do
            click_on('Delete')
          end
        end

        it 'shows me the list of services' do
          within('#content') do
            expect(page).to have_content(I18n.t(:heading, scope: [:services, :index]))
          end
        end

        it 'shows me a message saying it was deleted successfully' do
          expect(page).to have_content('Service "My First Service" deleted successfully')
        end
      end

      describe 'Editing a service' do
        before do
          visit '/services'
          find('a', text: 'Edit').click()
        end

        it 'shows me the Edit Service form' do
          expect(page).to have_content("Edit '#{service_name}'")
        end

        describe 'changing the name' do
          before do
            fill_in(I18n.t(:name, scope: [:helpers, :label, :service]), with: new_name)
            click_button 'Save'
          end
          context 'to something valid' do
            let(:new_name) { 'My First Service v2' }

            it 'shows me a message saying it was updated successfully' do
              expect(page).to have_content(I18n.t(:success, scope: [:services, :update], service: new_name))
            end
          end

          context 'to something invalid' do
            let(:new_name) { '?' }

            it 'shows me an error message' do
              expect(page).to have_content('Form name is too short')
            end

            it 'keeps me editing my service' do
              expect(page).to have_content("Edit '#{new_name}'")
            end
          end
        end

        describe 'changing the slug' do
          context 'to something valid' do
            let(:slug_name) { 'test-slug' }
            before do
              fill_in(I18n.t(:slug, scope: [:helpers, :label, :service]), with: slug_name)
              click_button('Save')
            end

            it 'alerts user that renamed slug will clear related user data store records' do
              expect(page).to have_content(I18n.t(:confirm, scope: [:services, :update]))
            end

            context 'when user confirms new slug name' do
              before do
                click_button(I18n.t(:confirm, scope: [:services, :edit_confirm]))
              end
              it 'successfully saves changes' do
                expect(page).to have_content(I18n.t(:success, scope: [:services, :update], service: service_name))
              end
            end

            context 'when user rejects new slug name' do
              before do
                click_link(I18n.t(:dismiss, scope: [:services, :edit_confirm]))
              end

              it 'returns user back to edit service screen' do
                expect(page).to have_content("Edit '#{service_name}'")
              end
            end
          end

          context 'to something invalid' do
            let(:slug_name) { '3' }
            before do
              fill_in(I18n.t(:slug, scope: [:helpers, :label, :service]), with: slug_name)
            end

            it 'does not update the service slug' do
              expect(page).to have_content("Edit '#{service_name}'")
            end
          end
        end
      end
    end

    context 'accessing a form via url that you do not have permissions to view' do
      let(:other_user) {User.create(name: 'other user', email: 'other_user@example.justice.gov.uk') }
      let(:other_service) do
        Service.create(name: 'Leavers Form',
                       git_repo_url: 'https://some-repo.git',
                       created_by_user: other_user)
      end
      before do
        visit "/services/#{other_service.slug}"
      end

      it 'redirects user to services index page' do
        within('h1') do
          expect(page).to have_content(I18n.t(:heading, scope: [:services, :index]))
        end
      end

      it 'displays an error alert message' do
        expect(page).to have_content(I18n.t(:pundit_not_authorized_error, scope: [:errors, :pundit]))
      end
    end

    describe 'entering a form name via url that does not exist' do
      before do
        visit '/services/a-non-existent-form'
      end

      it 'redirects user to services index page' do
        within('h1') do
          expect(page).to have_content(I18n.t(:heading, scope: [:services, :index]))
        end
      end

      it 'displays an error alert message' do
        expect(page).to have_content(I18n.t(:pundit_not_defined_error, scope: [:errors, :pundit]))
      end
    end
  end
end
