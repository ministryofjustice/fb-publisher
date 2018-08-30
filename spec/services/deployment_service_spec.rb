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
      it 'returns an instance of the class matching the given environments deployment_adapter' do
        expect(described_class.adapter_for(:made_up_slug)).to be_a(MinikubeAdapter)
      end

      describe 'the returned adapter' do
        it "has environment set to the environment with the given environment_slug" do
          expect(described_class.adapter_for(:made_up_slug).environment).to eq(mock_env)
        end
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

  describe '.configure_env_vars' do
    let(:adapter) { double('adapter') }
    let(:json_sub_dir) { nil }
    let(:deployment) { double('deployment', json_sub_dir: json_sub_dir) }
    before do
      allow(described_class).to receive(:adapter_for).with('myenv').and_return(adapter)
      allow(adapter).to receive(:configure_env_vars).and_return('configure_env_vars_result')
      allow(FileUtils).to receive(:mkdir_p).with('/my/config/dir')
    end

    it 'makes the config_dir including parents if needed' do
      expect(FileUtils).to receive(:mkdir_p).with('/my/config/dir')
      described_class.configure_env_vars(service: 'myservice', deployment: deployment, environment_slug: 'myenv', config_dir: '/my/config/dir')
    end

    it 'gets the adapter for the given environment_slug' do
      expect(described_class).to receive(:adapter_for).with('myenv').and_return(adapter)
      described_class.configure_env_vars(service: 'myservice', deployment: deployment, environment_slug: 'myenv', config_dir: '/my/config/dir')
    end

    it 'asks the adapter to configure_env_vars with the given service' do
      expect(adapter).to receive(:configure_env_vars).with(service: 'myservice', config_dir: '/my/config/dir', system_config: anything).and_return('configure_env_vars_result')
      described_class.configure_env_vars(service: 'myservice', deployment: deployment, environment_slug: 'myenv', config_dir: '/my/config/dir')
    end

    it 'returns the result of configure_env_vars from the adapter' do
      expect(described_class.configure_env_vars(service: 'myimage', deployment: deployment, environment_slug: 'myenv', config_dir: '/my/config/dir')).to eq('configure_env_vars_result')
    end
  end

  describe '.stop_service' do
    let(:adapter) { double('adapter') }
    before do
      allow(described_class).to receive(:adapter_for).with('myenv').and_return(adapter)
      allow(adapter).to receive(:stop_service).and_return('importedresult')
    end

    it 'gets the adapter for the given environment_slug' do
      expect(described_class).to receive(:adapter_for).with('myenv').and_return(adapter)
      described_class.stop_service(service: 'myservice', environment_slug: 'myenv')
    end

    it 'asks the adapter to stop_service with the given service and environment_slug' do
      expect(adapter).to receive(:stop_service).with(service: 'myservice').and_return('importedresult')
      described_class.stop_service(service: 'myservice', environment_slug: 'myenv')
    end

    it 'returns the result of stop_service' do
      expect(described_class.stop_service(service: 'myservice', environment_slug: 'myenv')).to eq('importedresult')
    end
  end


  describe '.url_for' do
    let(:adapter) { double('adapter') }
    before do
      allow(described_class).to receive(:adapter_for).with('myenv').and_return(adapter)
      allow(adapter).to receive(:url_for).and_return('importedresult')
    end

    it 'gets the adapter for the given environment_slug' do
      expect(described_class).to receive(:adapter_for).with('myenv').and_return(adapter)
      described_class.url_for(service: 'myservice', environment_slug: 'myenv')
    end

    it 'asks the adapter to url_for with the given service and environment_slug' do
      expect(adapter).to receive(:url_for).with(service: 'myservice').and_return('importedresult')
      described_class.url_for(service: 'myservice', environment_slug: 'myenv')
    end

    it 'returns the result of url_for' do
      expect(described_class.url_for(service: 'myservice', environment_slug: 'myenv')).to eq('importedresult')
    end

    context 'if the url_for fails' do
      before do
        allow(adapter).to receive(:url_for).and_raise(CmdFailedError)
      end

      it 'does not throw an exception' do
        expect { described_class.url_for(service: 'myservice', environment_slug: 'myenv') }.to_not raise_error
      end
    end
  end

  describe '.empty_deployment' do
    let(:service){ Service.new(name: 'my service', slug: 'my-service') }

    it 'returns a new ServiceDeployment' do
      expect(described_class.empty_deployment(service: service, environment_slug: 'my-env-slug')).to be_a(ServiceDeployment)
    end

    describe 'returned object' do
      let(:returned_object) { described_class.empty_deployment(service: service, environment_slug: 'my-env-slug') }

      it 'has the given service' do
        expect(returned_object.service).to eq(service)
      end

      it 'has the given environment_slug' do
        expect(returned_object.environment_slug).to eq('my-env-slug')
      end
    end
  end

  describe '.default_runner_image_ref' do
    it 'is "aldavidson/fb-runner-node:latest"' do
      expect(described_class.default_runner_image_ref).to eq('aldavidson/fb-runner-node:latest')
    end
  end

  describe '.setup_service' do
    let(:mock_adapter) { double('adapter', setup_service: true) }
    let(:args) {
      {
        environment_slug: 'env_slug',
        service: 'service',
        deployment: 'deployment',
        config_dir: 'config_dir'
      }
    }
    before do
      allow(FileUtils).to receive(:mkdir_p)
      allow(described_class).to receive(:adapter_for).and_return(mock_adapter)
    end

    it 'creates the config dir' do
      expect(FileUtils).to receive(:mkdir_p).with('config_dir')
      described_class.setup_service(args)
    end

    it 'gets the adapter for the given environment_slug' do
      expect(described_class).to receive(:adapter_for).with('env_slug').and_return(mock_adapter)
      described_class.setup_service(args)
    end

    it 'asks the adapter to setup_service passing on all args' do
      expect(described_class).to receive(:setup_service).with(args).and_return(mock_adapter)
      described_class.setup_service(args)
    end
  end

  describe '.expose' do
    let(:mock_adapter) { double('adapter', expose: true) }
    let(:args) {
      {
        environment_slug: 'env_slug',
        service: 'service',
        container_port: 'container_port',
        config_dir: 'config_dir'
      }
    }
    before do
      allow(described_class).to receive(:adapter_for).and_return(mock_adapter)
    end

    it 'gets the adapter for the given environment_slug' do
      expect(described_class).to receive(:adapter_for).with('env_slug').and_return(mock_adapter)
      described_class.expose(args)
    end

    it 'asks the adapter to expose passing on all args except environment_slug' do
      expect(mock_adapter).to receive(:expose).with(args.except(:environment_slug)).and_return(mock_adapter)
      described_class.expose(args)
    end
  end

  describe '.start_service' do
    let(:mock_adapter) { double('adapter', start_service: true) }
    let(:args) {
      {
        environment_slug: 'env_slug',
        service: 'service',
        tag: 'tag'
      }
    }
    before do
      allow(described_class).to receive(:adapter_for).and_return(mock_adapter)
    end

    it 'gets the adapter for the given environment_slug' do
      expect(described_class).to receive(:adapter_for).with('env_slug').and_return(mock_adapter)
      described_class.start_service(args)
    end

    it 'asks the adapter to start_service passing on all args except environment_slug' do
      expect(mock_adapter).to receive(:start_service).with(args.except(:environment_slug)).and_return(mock_adapter)
      described_class.start_service(args)
    end
  end

  describe '.restart_service' do
    let(:mock_adapter) { double('adapter', delete_pods: true) }
    let(:args) {
      {
        environment_slug: 'env_slug',
        service: 'service'
      }
    }
    before do
      allow(described_class).to receive(:adapter_for).and_return(mock_adapter)
    end

    it 'gets the adapter for the given environment_slug' do
      expect(described_class).to receive(:adapter_for).with('env_slug').and_return(mock_adapter)
      described_class.restart_service(args)
    end

    it 'asks the adapter to delete_pods passing on all args except environment_slug' do
      expect(mock_adapter).to receive(:delete_pods).with(args.except(:environment_slug)).and_return(mock_adapter)
      described_class.restart_service(args)
    end
  end
end
