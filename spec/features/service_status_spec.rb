require 'capybara_helper'

describe 'viewing service status' do
  let(:user) { User.find_or_create_by(name: 'test user', email: 'test@example.justice.gov.uk') }
  let(:service) do
    Service.create!(name: 'ABC Service', git_repo_url: 'https://github.com/some-org/some-repo.git',
                    created_by_user: user)
  end
  before do
    login_as!(user)
  end

  describe 'deleting the service' do
    before do
      visit "/services/#{service.slug}"
    end

    it 'has a delete button' do
      expect(page).to have_link(I18n.t(:delete, scope: [:services, :show]))
    end

    it "has a link to the form's git repo" do
      expect(page).to have_selector("a[href='#{service.git_repo_url}']")
    end

    context "clicking 'Delete form'", js: true do
      let(:message) do
        accept_confirm do
          click_on(I18n.t(:delete, scope: [:services, :show]))
        end
      end

      before do
        message
      end

      it 'displays a confirmation alert pop-up' do
        expect(message).to eq("Are you sure you want to delete the service '#{service.name}'?")
      end

      it 'successfully deletes the form' do
        expect(page).to have_content(I18n.t(:success, scope: [:services, :destroy], service: service.name))
      end

      it "returns user to 'Your forms' page" do
        within('#content') do
          expect(page).to have_content(I18n.t(:heading, scope: [:services, :index]))
        end
      end
    end
  end

  describe 'no service status checks' do
    context 'with no completed deployments' do
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
    context 'with completed deployments' do
      before do
        completed_deployment
        visit "/services/#{service.slug}"
      end
      it 'does not show a status' do
        expect(page).not_to have_selector('span.status')
        expect(page).to have_selector('span', text: I18n.t('services.environment.no_deployment'))
      end
      it 'does show a `Check now` button' do
        expect(page).to have_button(I18n.t('services.environment.check_now'))
      end
    end
  end

  describe 'service status checks' do
    before do
      ServiceStatusCheck.create!(environment_slug: 'dev', status: 404, time_taken: 30.0,
                                 timestamp: Time.new, created_at: Time.new, updated_at: Time.new,
                                 url: 'url.test', service: service)
    end
    context 'with no deployments' do
      before do
        visit "/services/#{service.slug}"
      end
      it 'does show a status' do
        expect(page).to have_selector('span.status')
      end
      it 'does not show a `Check now` button' do
        expect(page).not_to have_button(I18n.t('services.environment.check_now'))
      end
    end
    context 'with completed deployments' do
      before do
        completed_deployment
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

  def completed_deployment
    ServiceDeployment.create!(commit_sha: 'f7735e5',
                              environment_slug: 'dev',
                              created_at: Time.new - 30,
                              updated_at: Time.new,
                              created_by_user: user,
                              service: service,
                              completed_at: Time.new,
                              status: 'completed',
                              json_sub_dir: '')
  end
end
