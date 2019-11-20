require 'rails_helper'
require 'webmock/rspec'

describe ServiceStatusCheck do
  let(:mock_response) { double('response', code: 404) }

  before do
    allow(DeploymentService).to receive(:url_for).and_return('url.test')
  end

  describe '.execute!' do
    before do
      allow_any_instance_of(described_class).to receive(:net_http_response).and_return(mock_response)
    end
    context 'given a service and environment_slug' do
      let(:service){ Service.new(slug: 'my-service') }
      let(:env){ :dev }
      let(:result){ described_class.execute!(service: service, environment_slug: env) }

      it 'returns a check' do
        expect(result).to be_a(ServiceStatusCheck)
      end
      it 'executes the check' do
        expect_any_instance_of(ServiceStatusCheck).to receive(:execute!).once
        result
      end
    end
  end

  describe '.execute_many!' do
    let(:dev_response) { {status: 200} }
    let(:production_response) { {status: 404} }
    before do
      WebMock.stub_request(:get, "url1").to_return(dev_response)
      WebMock.stub_request(:get, "url2").to_return(production_response)
      allow_any_instance_of(ServiceStatusCheck).to receive(:save!)
    end

    context 'given a service and several environment_slugs' do
      let(:service){ Service.new(slug: 'my-service') }
      let(:envs){ [:dev, :production] }
      let(:result) do
        described_class.execute_many!(service: service, environment_slugs: envs)
      end
      before do
        allow(DeploymentService).to receive(:url_for).with(service: service, environment_slug: 'dev').and_return('url1')
        allow(DeploymentService).to receive(:url_for).with(service: service, environment_slug: 'production').and_return('url2')
      end

      it 'returns an array of checks' do
        expect(result.size).to eq(2)
      end

      describe 'each check' do
        it 'has url populated' do
          expect(result.map(&:url).compact.size).to eq(2)
        end
        it 'has the status populated' do
          expect(result.map(&:status)).to eq([200, 404])
        end
      end
    end
  end

  describe '#net_http_response' do
    subject { ServiceStatusCheck.new(url: 'http://my.service/') }
    let!(:stubbed_request) do
      WebMock.stub_request(:get, 'http://my.service/').to_return(status: 789)
    end

    it 'GETs the url' do
      subject.net_http_response
      expect(stubbed_request).to have_been_requested
    end

    context 'when no error is raised' do
      it 'returns the response' do
        expect(subject.send(:net_http_response).code).to eq("789")
      end
    end

    context 'when an error is raised' do
      before do
        WebMock.stub_request(:get, 'http://my.service/').to_raise(error_class)
      end
      context 'of type SocketError' do
        let(:error_class){ SocketError }
        it 'returns nil' do
          expect(subject.send(:net_http_response)).to be_nil
        end
      end
      context 'of type Net::OpenTimeout' do
        let(:error_class){ Net::OpenTimeout }
        it 'returns nil' do
          expect(subject.send(:net_http_response)).to be_nil
        end
      end
    end
  end

  describe '.latest' do
    context 'with matching records' do
      let!(:user){ User.create!(name: 'test user', email: 'test@user.com')}
      let!(:service_1){ Service.create!(name: 'My Service 1', created_by_user: user, git_repo_url: 'https://example.com/example1.git') }
      let!(:service_2){ Service.create!(name: 'My Service 2', created_by_user: user, git_repo_url: 'https://example.com/example2.git') }

      let!(:new_check){ ServiceStatusCheck.create!(service_id: service_1.id, environment_slug: 'dev', timestamp: Time.now - 1.second) }
      let!(:old_check){ ServiceStatusCheck.create!(service_id: service_1.id, environment_slug: 'dev', timestamp: Time.now - 1.hour) }
      let!(:newest_check_from_other_service){ ServiceStatusCheck.create!(service_id: service_2.id, environment_slug: 'dev', timestamp: Time.now) }
      let!(:new_check_from_other_env){ ServiceStatusCheck.create!(service_id: service_1.id, environment_slug: 'production', timestamp: Time.now - 1.second) }

      it 'returns the latest check matching the given service and environment_slug' do
        expect(described_class.latest(service_id: service_1.id, environment_slug: :dev)).to eq(new_check)
      end
    end
  end
end
