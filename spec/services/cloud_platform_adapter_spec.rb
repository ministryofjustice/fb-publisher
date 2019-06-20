require 'rails_helper'

describe CloudPlatformAdapter do
  describe '#create_network_policy' do
    let(:mock_adapter) { double('adapter').as_null_object }

    before :each do
      FileUtils.rm_f('/tmp/network_policy.yaml')

      stub_const('PLATFORM_ENV', 'test')
    end

    subject do
      described_class.new(environment: nil, kubernetes_adapter: mock_adapter)
    end

    it 'generates network_policy.yaml' do
      subject.create_network_policy(config_dir: '/tmp/',
                                    environment_slug: 'dev')

      expect(File.exist?('/tmp/network_policy.yaml')).to be_truthy
    end

    it 'generates network_policy.yaml with correct contents' do
      subject.create_network_policy(config_dir: '/tmp',
                                    environment_slug: 'dev')

      contents = File.open('/tmp/network_policy.yaml').read

      expect(contents).to include('networking.k8s.io/v1')
      expect(contents).to include('namespace: formbuilder-services-test-dev')
      expect(contents).to include('name: formbuilder-platform-test-dev')
    end

    it 'applies network_policy.yaml' do
      expect(mock_adapter).to receive(:apply_file).with(file: '/tmp/network_policy.yaml').and_return(true)

      subject.create_network_policy(config_dir: '/tmp',
                                    environment_slug: 'dev')
    end
  end
end
