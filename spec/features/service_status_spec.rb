require 'capybara_helper'

describe 'viewing service status' do
  context 'as a logged in user' do
    let(:user) { User.find_or_create_by(name: 'test user', email: 'test@example.justice.gov.uk') }
    before do
      login_as!(user)
    end
    context 'when I have a service' do
      let(:service) do
        Service.create!(name: 'ABC Service', git_repo_url: 'https://github.com/some-org/some-repo.git',
                        created_by_user: user)
      end
      describe 'without deployments' do
        context 'when I have no service status checks' do
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
        context 'when I have a service status check' do
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
          it 'does not show a status' do
            expect(page).not_to have_selector('span.status')
            expect(page).to have_selector('span', text: I18n.t('services.environment.no_deployment'))
          end
          it 'does not show a `Check now` button' do
            expect(page).not_to have_button(I18n.t('services.environment.check_now'))
          end
        end
      end

      describe 'with deployments' do
        context 'when I have no service status checks' do
          context 'with a completed deployment' do
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
          context 'with a failed deployment' do
            before do
              failed_deployment
              visit "/services/#{service.slug}"
            end
            it 'shows a status' do
              expect(page).to have_selector('span.status')
            end

            it 'does not show a `Check now` button' do
              expect(page).not_to have_button(I18n.t('services.environment.check_now'))
            end
          end
        end
        context 'when I have a service status check' do
          before do
            ServiceStatusCheck.create!(environment_slug: 'dev',
                                       status: 1,
                                       time_taken: 30.0,
                                       timestamp: Time.new - (60 * 60 )* 24,
                                       created_at: Time.new - (60 * 60 )* 24,
                                       updated_at: Time.new - (60 * 60 )* 24,
                                       url: 'url.test',
                                       service: service)
          end
          context 'with a completed latest deployment' do
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
          context 'with a failed latest deployment' do
            before do
              failed_deployment
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

  def failed_deployment
    ServiceDeployment.create!(commit_sha: 'f7735e5',
                              environment_slug: 'dev',
                              created_at: Time.new - 30,
                              updated_at: Time.new,
                              created_by_user: user,
                              service: service,
                              completed_at: Time.new,
                              status: 'failed_non_retryable',
                              json_sub_dir: '')
  end
end
