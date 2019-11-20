require 'capybara_helper'

describe 'visiting services/deployment' do
  context 'as a logged in user' do
    let(:user) do
      User.create(id: 'abc123', name: 'test user',
                  email: 'test@example.justice.gov.uk')
    end

    let(:service) do
      Service.create!(id: 'fed456',
                      name: 'My New Service',
                      slug: 'my-new-service',
                      git_repo_url: 'https://github.com/ministryofjustice/fb-sample-json.git',
                      created_by_user: user)
    end

    before do
      login_as!(user)
    end

    describe '.index', js: true do
      context 'when there are more than 10 deployments' do
        before do
          11.times { create_deployment('dev', 'completed') }
        end

        it 'enables link to next page if total deployments are greater than 10' do
          visit "/services/#{service.slug}/deployments?env=dev"
          expect(page).to have_link('Next')
        end

        it 'enables link to previous page if not on the first page' do
          visit "/services/#{service.slug}/deployments?env=dev"
          click_link('Next')
          expect(page).to have_link('Prev')
        end
      end

      context 'when there are 10 or less deployments' do
        before do
          3.times { create_deployment('dev', 'completed') }
        end

        it 'does not enable link to next page' do
          visit "/services/#{service.slug}/deployments?env=dev"
          expect(page).to_not have_link('Next')
        end

        it 'does not enable link to previous page' do
          visit "/services/#{service.slug}/deployments?env=dev"
          expect(page).to_not have_link('Prev')
        end
      end

      it 'links deployment commit sha to Github' do
        create_deployment('dev', 'completed')
        visit "/services/#{service.slug}/deployments?env=dev"
        expect(page).to have_link('f7735e5', href: 'https://github.com/ministryofjustice/fb-sample-json/commit/f7735e5')
      end
    end

    describe '.status' do
      context 'when there are successful deployments to all environments' do
        before do
          ServiceDeployment.create!(commit_sha: 'f7735e5',
                                    environment_slug: 'dev',
                                    created_at: Time.new - 30,
                                    updated_at: Time.new,
                                    created_by_user: user,
                                    service: service,
                                    completed_at: Time.new,
                                    status: 'completed',
                                    json_sub_dir: '')

          ServiceDeployment.create!(commit_sha: 'e986a12',
                                    environment_slug: 'production',
                                    created_at: Time.new - 300,
                                    updated_at: Time.new - 240,
                                    created_by_user: user,
                                    service: service,
                                    completed_at: Time.new,
                                    status: 'completed',
                                    json_sub_dir: '')
        end

        it 'provides Github links to the latest deployments for each environment' do
          visit "/services/#{service.slug}/deployments/status"
          expect(page).to have_link('f7735e5', href: 'https://github.com/ministryofjustice/fb-sample-json/commit/f7735e5')
          expect(page).to have_link('e986a12', href: 'https://github.com/ministryofjustice/fb-sample-json/commit/e986a12')
        end
      end

      context 'when there is at least one successful deployment' do
        before do
          create_deployment('dev', 'completed')
          create_deployment('production', 'completed')
        end

        it 'has a link to a un-deploy button' do
          visit "/services/#{service.slug}/deployments/status"
          expect(page).to have_link('Un-deploy', count: 2)
        end
      end

      context 'when there are no deployments' do
        it 'does not show any un-deploy buttons' do
          visit "/services/#{service.slug}/deployments/status"
          expect(page).to_not have_link('Un-deploy')
        end
      end

      context 'when there are failed deployments' do
        before do
          create_deployment('dev', 'failed_non_retryable')
        end

        it 'does not show any un-deploy buttons' do
          visit "/services/#{service.slug}/deployments/status"
          expect(page).to_not have_link('Un-deploy')
        end
      end

      context 'when user clicks on `Un-deploy button`', js: true do
        before do
          create_deployment('dev', 'completed')
        end

        it 'removes the deployment if user confirms the alert' do
          visit "/services/#{service.slug}/deployments/status"
          accept_alert do
            click_link('Un-deploy')
          end

          expect(page).to_not have_link('Un-deploy')
        end

        it 'does not remove the deployment if user dismisses the alert' do
          visit "/services/#{service.slug}/deployments/status"

          dismiss_confirm do
            click_link 'Un-deploy'
          end

          expect(page).to have_link('Un-deploy', count: 1)
        end
      end
    end

    def create_deployment(environment_slug, status)
      ServiceDeployment.create!(commit_sha: 'f7735e5',
                                environment_slug: environment_slug,
                                created_at: Time.new - 30,
                                updated_at: Time.new,
                                created_by_user: user,
                                service: service,
                                completed_at: Time.new,
                                status: status,
                                json_sub_dir: '')
    end
  end
end
