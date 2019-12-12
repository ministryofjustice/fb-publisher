require 'capybara_helper'

describe "visiting a service's config params page" do
  context 'as a logged in user' do
    let(:email) { 'test@example.justice.gov.uk' }
    let(:service) do
      OpenStruct.new(name: 'Test Service',
                     slug: 'test-service',
                     git_repo_url: 'https://github.com/some_org/some_repo.git')
    end

    before do
      login_as!(email)
      create_service(service)
    end

    let(:name) { 'TEST_1' }
    let(:value) { 'abc456' }
    let(:environment) { 'Development' }

    context 'when adding new environment variables' do
      before do
        add_environment_variable(service: service,
                                 name: name,
                                 value: value,
                                 environment: environment)
      end

      it 'displays a message advising the user to deploy for changes to take effect' do
        expect(page).to have_selector('div.flash.flash-notice',
                                      text: "Config Param '#{name}' (#{environment}) created successfully. For the changes to take effect this needs to be deployed")
      end

      context 'and environment variable already exists' do
        before do
          add_environment_variable(service: service,
                                   name: name,
                                   value: value,
                                   environment: environment)
        end

        it 'redirects back to index page with correct service env' do
          expect(page.current_url).to match(/\/services\/test-service\/config_params\?env=dev/)
        end

        it 'displays error message' do
          expect(page).to have_content('Name has already been taken')
        end
      end
    end

    context 'when changing existing environment variables' do
      let(:changed_name) { 'TEST_2' }
      let(:changed_value) { 'xyz987' }

      before do
        visit "/services/#{service.slug}/config_params"
        click_on 'Edit'
        fill_in('Name', with: changed_name)
        fill_in('Value', with: changed_value)
        click_button('Save')
      end

      it 'displays a message advising the user to deploy for changes to take effect' do
        expect(page).to have_selector('div.flash.flash-notice',
                                      text: "Config Param 'TEST_2' (Development) updated successfully. For the changes to take effect this needs to be deployed")
      end
    end

    describe 'when a user is part of the same team' do
      let(:another_email) { 'another_user@example.justice.gov.uk' }

      before do
        logout!
        login_as!(another_email)
        logout!
        login_as!(email)
        create_team(name: 'MOJ Team')
        add_member_to_team(team_slug: 'moj-team', email: another_email)
        grant_permission_to_team(team_slug: 'moj-team', service_name: 'Test Service')
        logout!
      end

      context 'they can see the config params' do
        before do
          login_as!(another_email)

          visit "/services/#{service.slug}/config_params"
        end

        it "shows the config name and value" do
          expect(page).to have_content('TEST_2')
          expect(page).to have_content('xyz987')
        end
      end
    end
  end
end
