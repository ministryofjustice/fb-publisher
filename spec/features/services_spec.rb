require 'capybara_helper'

describe 'visiting /services' do
  before do
    allow(DeploymentService).to receive(:url_for).and_return('url.test')
  end

  context 'as a logged in user' do
    let(:user) { User.find_or_create_by(name: 'test user', email: 'test@example.justice.gov.uk') }
    before do
      login_as!(user)
    end

    it 'shows a list of my services' do
      visit '/services'
      expect(page).to have_content('Your Services')
    end

    it 'has a link to create a new service' do
      visit '/services'
      expect(page).to have_link('Create a new service')
    end

    describe 'clicking "Create a new service"' do
      before do
        visit '/services'
        click_link('Create a new service')
      end

      it 'shows a New Service page' do
        expect(page).to have_content('New Service')
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

    describe 'filling in the New Service form' do
      before do
        visit new_service_path
      end

      it 'does not have a token field' do
        expect(page).to_not have_content(I18n.t(:token, scope: [:services, :form]))
      end

      context 'when I fill in the Service name' do
        before do
          fill_in('Service name', with: name)
        end
        context 'with a valid name' do
          let(:name) { 'My new service' }

          context 'and click Create Service' do
            before do
              click_on( 'Next' )
            end

            it 'does not submit the form' do
              expect(page).to have_content('New Service')
            end
          end

          context 'and fill in the git repo url' do
            before do
              fill_in('URL of the service config JSON Git repository', with: url)
            end
            context 'with a valid https git repo url' do
              let(:url) { 'https://git.example.com/repo.git' }

              context 'and click Create Service' do
                before do
                  click_on( 'Next' )
                end

                it 'shows me the status of my new service' do
                  expect(page).to have_content('Status of your service in the available environments')
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
      before do
        visit '/services/new'
        fill_in('Service name', with: 'My First Service')
        fill_in('URL of the service config JSON Git repository', with: 'https://repo.url/repo.git')
        find('input[value="Next"]').click()
      end

      describe 'Deleting a service', js: true do
        before do
          visit '/services'
          accept_confirm do
            click_on('Delete')
          end
        end

        it 'shows me the list of services' do
          expect(page).to have_content('Your Services')
        end

        it 'has deleted the service' do
          expect(page).to have_content("You don't have any services")
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
          expect(page).to have_content("Editing 'My First Service'")
        end

        describe 'changing the name' do
          before do
            fill_in('Service name', with: new_name)
            click_on('Update Service')
          end
          context 'to something valid' do
            let(:new_name) { 'My First Service v2' }

            it 'shows me a message saying it was updated successfully' do
              expect(page).to have_content(I18n.t(:success, scope: [:services, :update], service: new_name))
            end

            it 'shows me the status of my new service' do
              expect(page).to have_content('Status of your service in the available environments')
            end
          end

          context 'to something invalid' do
            let(:new_name) { '?' }

            it 'shows me an error message' do
              expect(page).to have_content('Service name is too short')
            end

            it 'keeps me editing my service' do
              expect(page).to have_content("Editing '#{new_name}'")
            end
          end
        end
      end
    end

    describe 'viewing service status' do
      context 'when I have a service' do
        let(:service) do
          Service.create!(name: 'ABC Service', git_repo_url: 'https://github.com/some-org/some-repo.git',
                          created_by_user: user)
        end

        context 'with no deployments' do
          before do
            visit "/services/#{service.slug}"
          end

          it 'does not show a status' do
            expect(page).not_to have_selector('span.status')
            expect(page).to have_selector('span', text: I18n.t('services.environment.no_deployment'))
          end

          it 'does not show a `Check now` button' do
            expect(page).not_to have_button(I18n.t('services.environment.check_now'))
          end
        end

        context 'with deployments' do
          before do
            ServiceStatusCheck.create!(environment_slug: 'dev',
                                       status: 1,
                                       time_taken: 30.0,
                                       timestamp: Time.new,
                                       created_at: Time.new,
                                       updated_at: Time.new,
                                       url: 'url.test',
                                       service: service)

            visit "/services/#{service.slug}"
          end

          it 'does show a status' do
            expect(page).to have_selector('span.status')
          end

          it 'does show a `Check now` button' do
            expect(page).to have_button(I18n.t('services.environment.check_now'))
          end
        end
      end
    end
  end
end
