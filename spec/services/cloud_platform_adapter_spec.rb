require 'rails_helper'

describe CloudPlatformAdapter do
  describe '#setup_service' do
    let(:mock_adapter) { double('adapter').as_null_object }
    let(:service) { double('service').as_null_object }
    let(:config_dir) { '/tmp' }

    before :each do
      FileUtils.rm_f('/tmp/network_policy.yaml')

      stub_const('PLATFORM_ENV', 'test')
    end

    subject do
      described_class.new(environment: nil, kubernetes_adapter: mock_adapter)
    end

    it 'calls create_service' do
      expect(mock_adapter).to receive(:create_service).with(service: service,
                                                            config_dir: config_dir)

      subject.setup_service(service: service,
                            deployment: double('deployment').as_null_object,
                            config_dir: config_dir,
                            image: double('image'))
    end
  end

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

  describe '#create_service_monitor' do
    let(:mock_adapter) { double('adapter').as_null_object }
    let(:path) { '/tmp/service_monitor.yaml' }
    let(:service) { Service.new(slug: 'ioj') }

    before :each do
      FileUtils.rm_f(path)

      stub_const('PLATFORM_ENV', 'test')
    end

    subject do
      described_class.new(environment: nil, kubernetes_adapter: mock_adapter)
    end

    it 'generates service_monitor.yaml' do
      subject.create_service_monitor(service: service,
                                     config_dir: '/tmp/',
                                     environment_slug: 'dev')

      expect(File.exist?(path)).to be_truthy
    end

    it 'generates service_monitor.yaml with correct contents' do
      subject.create_service_monitor(service: service,
                                     config_dir: '/tmp',
                                     environment_slug: 'dev')

      hash = YAML.load_stream(File.open(path))

      expect(hash.dig(0, 'apiVersion')).to eql('monitoring.coreos.com/v1')
      expect(hash.dig(0, 'kind')).to eql('ServiceMonitor')

      expect(hash.dig(0, 'metadata', 'name')).to eql('formbuilder-form-ioj-service-monitor-test-dev')
      expect(hash.dig(0, 'metadata', 'namespace')).to eql('formbuilder-services-test-dev')

      expect(hash.dig(0, 'spec', 'selector', 'matchLabels', 'run')).to eql('ioj')

      expect(hash.dig(1, 'apiVersion')).to eql('networking.k8s.io/v1')
      expect(hash.dig(1, 'kind')).to eql('NetworkPolicy')

      expect(hash.dig(1, 'metadata', 'name')).to eql('formbuilder-form-ioj-service-monitor-ingress-test-dev')
      expect(hash.dig(1, 'metadata', 'namespace')).to eql('formbuilder-services-test-dev')

      expect(hash.dig(1, 'spec', 'podSelector', 'matchLabels', 'run')).to eql('ioj')
    end

    it 'applies service_monitor.yaml' do
      expect(mock_adapter).to receive(:apply_file).with(file: '/tmp/service_monitor.yaml').and_return(true)

      subject.create_service_monitor(service: service,
                                     config_dir: '/tmp',
                                     environment_slug: 'dev')
    end
  end
end
