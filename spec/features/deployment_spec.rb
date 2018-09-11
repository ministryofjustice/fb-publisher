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
          11.times { create_deployment }
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
          3.times { create_deployment }
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
    end

    def create_deployment
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
end