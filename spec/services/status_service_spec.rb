require 'rails_helper'

describe StatusService do
  let(:service){ double(Service, id: 'abcd', slug: 'my-service') }
  let(:check_dev){ double(ServiceStatusCheck) }
  let(:check_staging){ double(ServiceStatusCheck) }


  describe '.service_status' do
    describe 'given multiple environment_slugs' do
      let(:slugs) { [:dev, :staging] }

      it 'calls last_status for each environment, passing the service & environment_slug' do
        expect(described_class).to receive(:last_status).at_least(:once).with(service: service, environment_slug: :dev).and_return(check_dev)
        expect(described_class).to receive(:last_status).at_least(:once).with(service: service, environment_slug: :staging).and_return(check_staging)
        described_class.service_status(service, environment_slugs: slugs)
      end

      context 'when last_status returns a value' do
        before do
          allow(described_class).to receive(:last_status).with(service: service, environment_slug: :dev).and_return(check_dev)
          allow(described_class).to receive(:last_status).with(service: service, environment_slug: :staging).and_return(check_staging)
        end

        it 'returns that value in the array' do
          expect(described_class.service_status(service, environment_slugs: slugs)).to eq([check_dev, check_staging])
        end
      end

      context 'when last_status returns nil' do
        let(:empty_check){ double(ServiceStatusCheck) }
        before do
          allow(described_class).to receive(:last_status).with(service: service, environment_slug: :dev).and_return(nil)
          allow(described_class).to receive(:last_status).with(service: service, environment_slug: :staging).and_return(check_staging)
          allow(described_class).to receive(:empty_check).with(service: service, environment_slug: :dev).and_return(empty_check)
        end

        it 'returns an empty_check in the array' do
          expect(described_class.service_status(service, environment_slugs: slugs)).to eq([empty_check, check_staging])
        end
      end
    end
  end

  describe '.last_status' do
    let(:mock_check) { double(ServiceStatusCheck, id: "1234") }
    before do
      allow(ServiceStatusCheck).to receive(:latest).with(service_id: service.id, environment_slug: :dev).and_return(mock_check)
    end
    it 'returns the latest check for the given service and environment_slug' do
      expect(described_class.last_status(service: service, environment_slug: :dev)).to eq(mock_check)
    end
  end

  describe '.check' do
    it 'calls execute! on the ServiceStatusCheck with the given args' do
      expect(ServiceStatusCheck).to receive(:execute!).with(environment_slug: :dev, service: service, timeout: 2).and_return 'execute result'
      described_class.check(environment_slug: :dev, service: service, timeout: 2)
    end

    it 'returns the result of .check' do
      allow(ServiceStatusCheck).to receive(:execute!).with(environment_slug: :dev, service: service, timeout: 2).and_return 'execute result'
      expect(described_class.check(environment_slug: :dev, service: service, timeout: 2)).to eq('execute result')
    end
  end

  describe '.check_in_parallel' do
    it 'calls execute_many! on the ServiceStatusCheck with the given args' do
      expect(ServiceStatusCheck).to receive(:execute_many!).with(environment_slugs: [:dev, :staging], service: service, timeout: 2).and_return 'execute_many result'
      described_class.check_in_parallel(environment_slugs: [:dev, :staging], service: service, timeout: 2)
    end

    it 'returns the result of .check' do
      allow(ServiceStatusCheck).to receive(:execute_many!).with(environment_slugs: [:dev, :staging], service: service, timeout: 2).and_return 'execute_many result'
      expect(described_class.check_in_parallel(environment_slugs: [:dev, :staging], service: service, timeout: 2)).to eq('execute_many result')
    end
  end

  describe '.empty_check' do
    let(:service) { Service.new(slug: 'my-new-service') }
    describe 'return value' do
      let(:return_value){ described_class.send(:empty_check, service: service, environment_slug: :dev) }

      it 'is a ServiceStatusCheck' do
        expect(return_value).to be_a(ServiceStatusCheck)
      end
      it 'is not persisted' do
        expect(return_value).to_not be_persisted
      end
      it 'has the given service' do
        expect(return_value.service).to eq(service)
      end
      it 'has the given environment_slug as a string' do
        expect(return_value.environment_slug).to eq('dev')
      end

      it 'has nil url' do
        expect(return_value.url).to be_nil
      end
    end
  end
end
