require 'capybara_helper'

describe 'visiting services/deployment' do
  let(:user) do
    User.create(id: 'abc123', name: 'test user',
                email: 'test@example.justice.gov.uk')
  end

  before do
    login_as!(user)
  end

  context 'as a logged in user' do
    describe '.index', js: true do
      let(:service) do
        Service.create!(id: 'fed456',
                        name: 'My New Service',
                        slug: 'my-new-service',
                        git_repo_url: 'https://github.com/ministryofjustice/fb-sample-json.git',
                        created_by_user: user)
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

    describe '.show', js: true do
      context 'when adding a new deployment' do
        it 'creates a link to the commit sha on Github' do
          create_service
          visit '/services/a-different-service/deployments/status'
          click_link('Deploy Now', match: :first)
          fill_in('Commit SHA, branch, or tag', with: 'f7735e5')
          click_button('Deploy now')
          find_link('f7735e5', wait: 60)
          expect(page).to have_link(href: 'https://github.com/ministryofjustice/fb-sample-json/commit/f7735e5')
        end
      end

      def create_service
        visit '/services/new'
        fill_in('Service name', with: 'A Different Service')
        fill_in('URL of the service config JSON Git repository', with: 'https://github.com/ministryofjustice/fb-sample-json.git')
        click_button('Next')
      end
    end
  end
end
