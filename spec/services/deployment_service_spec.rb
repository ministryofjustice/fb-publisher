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
end
