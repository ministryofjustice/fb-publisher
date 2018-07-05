require 'rails_helper'

describe DeploymentService do
  let(:service){ double(Service, id: 'abcd', slug: 'my-service') }
  let(:deployment_dev){ double(ServiceDeployment) }
  let(:deployment_staging){ double(ServiceDeployment) }


  describe '.service_status' do
    describe 'given multiple environment_slugs' do
      let(:slugs) { [:dev, :staging] }

      it 'calls last_status for each environment, passing the service & environment_slug' do
        expect(described_class).to receive(:last_status).at_least(:once).with(service: service, environment_slug: :dev).and_return(deployment_dev)
        expect(described_class).to receive(:last_status).at_least(:once).with(service: service, environment_slug: :staging).and_return(deployment_staging)
        described_class.service_status(service, environment_slugs: slugs)
      end

      context 'when last_status returns a value' do
        before do
          allow(described_class).to receive(:last_status).with(service: service, environment_slug: :dev).and_return(deployment_dev)
          allow(described_class).to receive(:last_status).with(service: service, environment_slug: :staging).and_return(deployment_staging)
        end

        it 'returns that value in the array' do
          expect(described_class.service_status(service, environment_slugs: slugs)).to eq([deployment_dev, deployment_staging])
        end
      end

      context 'when last_status returns nil' do
        let(:empty_deployment){ double(ServiceDeployment) }
        before do
          allow(described_class).to receive(:last_status).with(service: service, environment_slug: :dev).and_return(nil)
          allow(described_class).to receive(:last_status).with(service: service, environment_slug: :staging).and_return(deployment_staging)
          allow(described_class).to receive(:empty_deployment).with(service: service, environment_slug: :dev).and_return(empty_deployment)
        end

        it 'returns an empty_deployment in the array' do
          expect(described_class.service_status(service, environment_slugs: slugs)).to eq([empty_deployment, deployment_staging])
        end
      end
    end
  end

  describe '.last_status' do
    let(:mock_deployment) { double(ServiceDeployment, id: "1234") }
    before do
      allow(ServiceDeployment).to receive(:latest).with(service_id: service.id, environment_slug: :dev).and_return(mock_deployment)
    end
    it 'returns the latest deployment for the given service and environment_slug' do
      expect(described_class.last_status(service: service, environment_slug: :dev)).to eq(mock_deployment)
    end
  end

  describe '.adapter_for' do
    context 'given an environment_slug' do
      let(:slug) { :made_up_slug }
      let(:mock_env) { double(ServiceEnvironment, deployment_adapter: 'minikube') }
      before do
        allow(ServiceEnvironment).to receive(:find).with(slug).and_return mock_env
      end
      it 'returns a class matching the given environments deployment_adapter' do
        expect(described_class.adapter_for(:made_up_slug)).to eq(MinikubeAdapter)
      end
    end
  end

  describe '.service_tag' do
    let(:result) do
      described_class.service_tag(
        environment_slug: environment_slug,
        service: service,
        version: version,
        repository_scope: repository_scope
      )
    end
    context 'given an environment_slug and service' do
      let(:environment_slug) { 'dev' }
      let(:service) { double(Service, slug: 'my-service-slug') }

      context 'and a version' do
        let(:version) { 'v1.2.3' }

        context 'and a repository_scope' do
          let(:repository_scope) { 'my-repo-scope' }

          it 'returns repository_scope/fb-service.slug-environment_slug:version' do
            expect(result).to eq('my-repo-scope/fb-my-service-slug-dev:v1.2.3')
          end
        end
        context 'and no repository_scope' do
          let(:result) do
            described_class.service_tag(
              environment_slug: environment_slug,
              service: service,
              version: version
            )
          end
          before do
            allow(ENV).to receive(:[]).with('REMOTE_DOCKER_USERNAME').and_return('me-at-docker')
          end

          it 'defaults repository_scope to ENV["REMOTE_DOCKER_USERNAME"]' do
            expect(result).to start_with('me-at-docker/')
          end
        end
      end

      context 'and no version' do
        let(:result) do
          described_class.service_tag(
            environment_slug: environment_slug,
            service: service
          )
        end

        it 'defaults version to latest' do
          expect(result).to end_with(':latest')
        end
      end
    end
  end
end
