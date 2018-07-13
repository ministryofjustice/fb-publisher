require 'capybara_helper'

describe 'visiting /services' do
  before do
    allow(DeploymentService).to receive(:url_for).and_return('url.test')
  end

  context 'as a logged in user' do
    let(:user){ User.create(id: 'abc123', name: 'test user', email: 'test@example.justice.gov.uk') }
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

    describe 'filling in the New Service form' do
      before do
        visit new_service_path
      end

      context 'when I fill in the Service name' do
        before do
          fill_in('Service name', with: name)
        end
        context 'with a valid name' do
          let(:name) { 'My new service' }

          context 'and click Create Service' do
            before do
              click_on( 'Create Service' )
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
                  click_on( 'Create Service' )
                end

                it 'shows me the status of my new service' do
                  expect(page).to have_content('Status of your service in the available environments')
                end

                it 'shows me a notice saying it was created successfully' do
                  expect(page).to have_content('Your new service has been created successfully')
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
        find('input[value="Create Service"]').click()
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
              expect(page).to have_content('Service "My First Service v2" updated successfully')
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
  end
end
