require 'capybara_helper'

describe "visiting a service's config params page" do
  context 'as a logged in user' do
    let(:user) { User.find_or_create_by(name: 'test user', email: 'test@example.justice.gov.uk') }
    let(:service) do
      Service.create(name: 'Test Service',
                     git_repo_url: 'https://github.com/some_org/some_repo.git',
                     created_by_user: user)
    end

    before do
      login_as!(user)
    end

    let(:name) { 'TEST_1' }
    let(:value) { 'abc456' }
    let(:environment) { 'Test' }

    context 'when adding new environment variables' do
      before do
        visit "/services/#{service.slug}/config_params"
        fill_in('Name', with: name)
        fill_in('Value', with: value)
        click_button(I18n.t('.services.config_params.form.add'))
      end

      it 'displays a message advising the user to deploy for changes to take effect' do
        expect(page).to have_selector('div.flash.flash-success',
                                      text: I18n.t('services.config_params.create.success',
                                                   name: name, environment: environment))
      end

      context 'and environment variable already exists' do
        before do
          visit "/services/#{service.slug}/config_params"
          fill_in('Name', with: name)
          fill_in('Value', with: value)
          click_button(I18n.t('.services.config_params.form.add'))
        end

        it 'redirects back to index page with correct service env' do
          expect(page.current_url).to eql('http://www.example.com/services/test-service/config_params?env=dev')
        end

        it 'displays error message' do
          expect(page).to have_content('Name has already been taken')
        end
      end
    end

    context 'when changing existing environment variables' do
      let(:env_slug) { 'dev' }
      let(:config) do
        ServiceConfigParam.create!(environment_slug: env_slug,
                                   name: name,
                                   value: value,
                                   service: service,
                                   last_updated_by_user: user)
      end

      let(:changed_name) { 'TEST_2' }
      let(:changed_value) { 'xyz987' }

      before do
        visit "/services/#{service.slug}/config_params/#{config.id}/edit"
        fill_in('Name', with: changed_name)
        fill_in('Value', with: changed_value)
        click_button('Save')
      end

      it 'displays a message advising the user to deploy for changes to take effect' do
        expect(page).to have_selector('div.flash.flash-success',
                                      text: I18n.t('services.config_params.update.success',
                                                   name: changed_name, environment: environment))
      end
    end

    describe 'when a user is part of a team' do
      let(:another_user) { User.create!(name: 'another user', email: 'another_user@example.justice.gov.uk') }
      let(:team) { Team.create!(name: 'MOJ Team', created_by_user_id: another_user.id) }

      before do
        TeamMember.create!(user_id: user.id, team_id: team.id, created_by_user: another_user)
        TeamMember.create!(user_id: another_user.id, team_id: team.id, created_by_user: another_user)
      end

      context 'they can see the config params on a form edited by another user' do
        let(:another_service) do
          Service.create!(name: 'Another Service',
                          created_by_user: another_user,
                          git_repo_url: 'https://github.com/some_org/some_repo.git')
        end
        let(:config_name) { 'HELLO' }
        let(:config_value) { 'World' }

        before do
          Permission.create!(service_id: another_service.id, team_id: team.id, created_by_user_id: another_user.id)
          ServiceConfigParam.create!(environment_slug: 'dev',
                                     name: config_name,
                                     value: config_value,
                                     last_updated_by_user_id: another_user.id,
                                     service_id: another_service.id)

          visit "/services/#{another_service.slug}/config_params"
        end

        it "shows the config name set for 'Another Service'" do
          expect(page).to have_content(config_name)
        end

        it "shows the config value set for 'Another Service'" do
          expect(page).to have_content(config_value)
        end
      end
    end
  end
end
