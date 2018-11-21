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
    let(:environment) { 'Development' }

    context 'when adding new environment variables' do
      before do
        visit "/services/#{service.slug}/config_params"
        fill_in('Name', with: name)
        fill_in('Value', with: value)
        click_button(I18n.t('.services.config_params.form.add'))
      end

      it 'displays a message advising the user to deploy for changes to take effect' do
        expect(page).to have_selector('div.flash.flash-notice',
                                      text: I18n.t('services.config_params.create.success',
                                                   name: name, environment: environment))
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
        expect(page).to have_selector('div.flash.flash-notice',
                                      text: I18n.t('services.config_params.update.success',
                                                   name: changed_name, environment: environment))
      end
    end
  end
end
