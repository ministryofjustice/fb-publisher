require 'rails_helper'

describe GenericKubernetesPlatformAdapter do
  subject do
    described_class.new(environment: double('dev', slug: 'dev'))
  end

  describe '#configure_env_vars' do
    let(:system_config) do
      {'system_var_1' => 'system value 1'}
    end
    let(:config_dir) { '/config/dir' }
    let(:user) { User.new(name: 'user', email: 'user@example.com') }
    let!(:service) { Service.create!(name: 'my service', created_by_user: user, git_repo_url: 'https://git/repo') }
    let(:service_token) { service.service_config_params.find_by(name: 'SERVICE_TOKEN', environment_slug: :dev).value }
    let(:service_secret) { service.service_config_params.find_by(name: 'SERVICE_SECRET', environment_slug: :dev).value }
    let(:encoded_public_key) { service.service_config_params.find_by(name: 'ENCODED_PUBLIC_KEY', environment_slug: :dev).value }
    let(:encoded_private_key) { service.service_config_params.find_by(name: 'ENCODED_PRIVATE_KEY', environment_slug: :dev).value }
    let!(:dev_param) do
      ServiceConfigParam.create!(service: service, environment_slug: :dev, name: 'PARAM_1', value: 'dev "{value}\' 1', last_updated_by_user: user)
    end

    before do
      allow(subject.kubernetes_adapter).to receive(:set_environment_vars)
    end

    it 'asks the kubernetes_adapter to set the ServiceConfigParams for the given environment ' do
      expect(subject.kubernetes_adapter).to receive(:set_environment_vars).with(
        service: service,
        config_dir: config_dir,
        vars: {'PARAM_1' => 'dev "{value}\' 1',
               'SERVICE_TOKEN' => service_token,
               'SERVICE_SECRET' => service_secret,
               'ENCODED_PUBLIC_KEY' => encoded_public_key,
               'ENCODED_PRIVATE_KEY' => encoded_private_key,
               'system_var_1' => 'system value 1'}
      ).and_return({'key' => 'value'})
      subject.configure_env_vars(service: service, config_dir: config_dir, system_config: system_config)
    end

    context 'when the kubernetes_adapter raises a CmdFailedError' do
      before do
        allow(subject.kubernetes_adapter).to receive(:set_environment_vars).and_raise(CmdFailedError)
      end

      it 'swallows the exception and does not bubble it out' do
        expect{ subject.configure_env_vars(service: service, config_dir: config_dir, system_config: system_config) }.to_not raise_error
      end
    end
  end

  describe '.service_is_running?' do
    let(:service) { Service.new(name: 'my service', slug: 'my-service') }
    let(:exists) { 'oh yes' }
    before do
      allow(subject.kubernetes_adapter).to receive(:exists_in_namespace?).and_return(exists)
    end

    it 'asks the kubernetes_adapter if the service exists in the namespace' do
      expect(subject.kubernetes_adapter).to receive(:exists_in_namespace?).with(
        name: 'my-service',
        type: 'service'
      ).and_return(true)
      subject.service_is_running?(service: service)
    end

    it 'returns the result of the kubernetes_adapter call' do
      expect(subject.service_is_running?(service: service)).to eq(exists)
    end
  end

  describe '.deployment_exists?' do
    let(:service) { Service.new(name: 'my service', slug: 'my-service') }
    let(:exists) { 'oh yes' }
    before do
      allow(subject.kubernetes_adapter).to receive(:exists_in_namespace?).and_return(exists)
    end

    it 'asks the kubernetes_adapter if a deployment exists with the name of the service' do
      expect(subject.kubernetes_adapter).to receive(:exists_in_namespace?).with(
        name: 'my-service',
        type: 'deployment'
      ).and_return(true)
      subject.deployment_exists?(service: service)
    end

    it 'returns the result of the kubernetes_adapter call' do
      expect(subject.deployment_exists?(service: service)).to eq(exists)
    end
  end

  describe '.delete_pods' do
    let(:service) { Service.new(name: 'my service', slug: 'my-service') }
    let(:result) { 'oh yes' }
    before do
      allow(subject.kubernetes_adapter).to receive(:delete_pods).and_return(result)
    end
    it 'asks the kubernetes_adapter to delete pods with a label of run=(service slug)' do
      expect(subject.kubernetes_adapter).to receive(:delete_pods).with(
        label: 'run=my-service'
      ).and_return(result)
      subject.delete_pods(service: service)
    end

    it 'returns the result of the kubernetes_adapter call' do
      expect(subject.delete_pods(service: service)).to eq(result)
    end
  end

  describe '.remove_ingress' do
    let(:service) { Service.new(name: 'my service', slug: 'my-service') }
    let(:result) { 'oh yes' }
    before do
      allow(subject.kubernetes_adapter).to receive(:delete_ingress).and_return(result)
    end

    it 'asks the kubernetes_adapter to delete ingress with the a specific name' do
      expect(subject.kubernetes_adapter).to receive(:delete_ingress).with(
        name: "#{service.slug}-ingress"
      ).and_return(result)
      subject.remove_ingress(slug: service.slug)
    end

    it 'returns the result of the kubernetes_adapter call' do
      expect(subject.remove_ingress(slug: service.slug)).to eq(result)
    end
  end

  describe '.delete_deployment' do
    let(:service) { Service.new(name: 'my service', slug: 'my-service') }
    let(:result) { 'oh yes' }
    before do
      allow(subject.kubernetes_adapter).to receive(:delete_deployment).and_return(result)
      allow(subject.kubernetes_adapter).to receive(:deployment_name).and_return('my deployment')
    end

    it 'asks the kubernetes_adapter for the deployment_name of the given service' do
      expect(subject.kubernetes_adapter).to receive(:deployment_name).with(
        service: service
      ).and_return('my deployment')
      subject.delete_deployment(service: service)
    end

    it 'asks the kubernetes_adapter to delete the deployment' do
      expect(subject.kubernetes_adapter).to receive(:delete_deployment).with(
        name: 'my deployment'
      ).and_return(result)
      subject.delete_deployment(service: service)
    end

    it 'returns the result of the kubernetes_adapter call' do
      expect(subject.delete_deployment(service: service)).to eq(result)
    end
  end

  describe '.stop_service' do
    let(:service) { Service.new(name: 'my service', slug: 'my-service') }
    let(:deployment_exists) { false }
    let(:running) { false }
    before do
      allow(subject).to receive(:service_is_running?).and_return(running)
      allow(subject).to receive(:deployment_exists?).and_return(deployment_exists)
    end
    context 'when the given service is running' do
      let(:running) { true }
      it 'asks the kubernetes_adapter to delete the service' do
        expect(subject.kubernetes_adapter).to receive(:delete_service).with( name: 'my-service' )
        subject.stop_service(service: service)
      end
    end
    context 'when the given service is not running' do
      let(:running) { false }
      it 'does not ask the kubernetes_adapter to delete the service' do
        expect(subject.kubernetes_adapter).to_not receive(:delete_service)
        subject.stop_service(service: service)
      end
    end

    context 'when the deployment exists' do
      let(:deployment_exists) { true }
      it 'asks the kubernetes_adapter to delete the deployment' do
        expect(subject.kubernetes_adapter).to receive(:delete_deployment).with( name: 'my-service' )
        subject.stop_service(service: service)
      end
    end
    context 'when the given deployment does not exist' do
      let(:deployment_exists) { false }
      it 'does not ask the kubernetes_adapter to delete the deployment' do
        expect(subject.kubernetes_adapter).to_not receive(:delete_deployment)
        subject.stop_service(service: service)
      end
    end
  end

  describe 'default_runner_image_ref' do
    context 'given a runner_repo' do
      before do
        allow(ENV).to receive(:[]).with('PLATFORM_ENV').and_return('runnerImagePlatformEnv')
      end
      let(:args) { {runner_repo: 'my-repo'} }

      context 'and an env_slug' do
        let(:args) { {runner_repo: 'my-repo', env_slug: 'my-slug'} }

        it 'returns "(runner_repo):latest-(platformEnv)"' do
          expect(subject.default_runner_image_ref(args)).to eq("my-repo:latest-runnerImagePlatformEnv")
        end
      end
      context 'but no env_slug' do
        it 'uses the slug from the environment attribute' do
          expect(subject.default_runner_image_ref(args)).to end_with(":latest-runnerImagePlatformEnv")
        end
      end
    end
    context 'given no runner_repo' do
      let(:args) { {} }
      before do
        allow(ENV).to receive(:[]).with('PLATFORM_ENV')
        allow(ENV).to receive(:[]).with('RUNNER_IMAGE_REPO').and_return('some-repo')
      end
      it 'uses the environment variable RUNNER_IMAGE_REPO' do
        expect(subject.default_runner_image_ref(args)).to start_with("some-repo:")
      end
    end
  end

  describe '#create_service_token_secret' do
    let(:user) { User.find_or_create_by(name: 'test user', email: 'test@example.justice.gov.uk') }
    let(:service) do
      Service.create(name: 'Test Service',
                     git_repo_url: 'https://github.com/some_org/some_repo.git',
                     created_by_user: user)
    end

    subject do
      described_class.new(environment: double('dev', slug: 'dev', namespace: 'namespace', kubectl_context: 'kube-context'))
    end

    it 'can create service token' do
      allow(subject.kubernetes_adapter).to receive(:apply_file)

      subject.create_service_token_secret(environment_slug: :dev, service: service, config_dir: '/tmp')
    end
  end
end
