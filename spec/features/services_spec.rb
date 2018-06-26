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

    it 'has a link to create a new service' do
      visit '/services'
      expect(page).to have_link('Create a new service')
    end

    context 'clicking "Create a new service"' do
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
            context 'with a valid git url' do
              let(:url) { 'git://git.example.com/repo.git' }

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
  end
end
