require 'rails_helper'

describe ServiceDeploymentStatus do
  describe '.all' do
    context 'with a valid service' do
      let(:user) do
        User.find_or_create_by(name: 'test user', email: 'test@example.justice.gov.uk')
      end

      let(:service) do
        Service.create!(id: '12345',
                        name: 'My First Service',
                        slug: 'my-first-slug',
                        git_repo_url: 'https://github.com/ministryofjustice/fb-sample-json.git',
                        created_by_user: user)
      end

      let(:status_service) do
        StatusService.service_status(service, environment_slugs: ServiceEnvironment.all_slugs)
      end

      let(:service_deployment_status) { ServiceDeploymentStatus.all(service) }

      it 'returns all the environment for the service' do
        expect(service_deployment_status.collect(&:status_environment_slug)).to eq(['dev', 'staging', 'production'])
      end

      it 'returns the service id for each environment' do
        service_id = service_deployment_status.collect(&:service_id).uniq.first
        expect(service_id).to eq(service.id)
      end

      it 'returns the service_slug for each environment' do
        slug = service_deployment_status.collect(&:service_slug).uniq.first
        expect(slug).to eq(service.slug)
      end

      it 'returns the service status for each environment' do
        expect(service_deployment_status.collect(&:service_status).count).to eq(3)
      end

      it 'returns the status url for each environment' do
        expect(service_deployment_status.collect(&:status_url).count).to eq(3)
      end

      it 'returns the timestamp for each environment' do
        expect(service_deployment_status.collect(&:status_timestamp).count).to eq(3)
      end

      context 'where no deployments exist' do
        let(:deployment) { nil }

        before do
          deployment
        end

        it 'returns the deployment_id to nil for each environment' do
          deploy_id = service_deployment_status.collect(&:deployment_id).uniq.first
          expect(deploy_id).to eq(nil)
        end

        it 'returns the deployment_status to nil for each environment' do
          deploy_status = service_deployment_status.collect(&:deployment_status).uniq.first
          expect(deploy_status).to eq(nil)
        end
      end

      context 'where deployments exist' do
        let(:deployment) do
          ServiceDeployment.create!(commit_sha: 'f238d3', environment_slug: 'dev', created_at: Time.new,
                                    updated_at: Time.new, created_by_user: user, service: service,
                                    completed_at: Time.new, status: 'completed', json_sub_dir: '')
        end

        before do
          deployment
        end

        it 'returns a valid deployment_id' do
          deploy_id = service_deployment_status.reject { |deploy| deploy.deployment_id.nil? }.collect(&:deployment_id).first
          expect(deploy_id).to eq(deployment.id)
        end

        it 'returns a valid deployment_status' do
          deploy_status = service_deployment_status.reject { |deploy| deploy.deployment_status.nil? }.collect(&:deployment_status).first
          expect(deploy_status).to eq(deployment.status)
        end
      end
    end
  end
end
