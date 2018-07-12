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

  describe '.build' do
    before do
      allow(LocalDockerService).to receive(:build)
    end
    let(:service) { double('service') }
    let(:json_dir) { '/my/json/dir' }
    let(:environment_slug) { 'dev' }

    context 'when no service_tag is given' do
      let(:result) do
        described_class.build(
          environment_slug: environment_slug,
          service: service,
          json_dir: json_dir
        )
      end
      before do
        allow(VersionControlService).to receive(:current_commit).with(dir: json_dir).and_return('mycommit')
        allow(described_class).to receive(:service_tag).and_return('myservicetag')
      end
      it 'gets the current commit of the json dir' do
        expect(VersionControlService).to receive(:current_commit).with(dir: json_dir).and_return('mycommit')
        result
      end
      it 'makes a service_tag with the current_commit' do
        expect(described_class).to receive(:service_tag).with(
          environment_slug: environment_slug,
          service: service,
          version: 'mycommit'
        ).and_return('myservicetag')
        result
      end
    end
    context 'when a tag is given' do
      let(:result) do
        described_class.build(
          environment_slug: environment_slug,
          service: service,
          json_dir: json_dir,
          tag: 'mytag'
        )
      end
      it 'asks the LocalDockerService to build with the given tag and json_dir' do
        expect(LocalDockerService).to receive(:build).with(tag: 'mytag', json_dir: json_dir)
        result
      end

      it 'returns the tag' do
        expect(result).to eq('mytag')
      end
    end
  end

  describe '.push' do
    let(:adapter) { double('adapter') }
    before do
      allow(described_class).to receive(:adapter_for).with('myenv').and_return(adapter)
      allow(adapter).to receive(:import_image).with(image: 'myimage').and_return('importedresult')
    end

    it 'gets the adapter for the given environment_slug' do
      expect(described_class).to receive(:adapter_for).with('myenv').and_return(adapter)
      described_class.push(image: 'myimage', environment_slug: 'myenv')
    end

    it 'asks the adapter to import_image with the given image' do
      expect(adapter).to receive(:import_image).with(image: 'myimage').and_return('importedresult')
      described_class.push(image: 'myimage', environment_slug: 'myenv')
    end

    it 'returns the result of import_image' do
      expect(described_class.push(image: 'myimage', environment_slug: 'myenv')).to eq('importedresult')
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
      expect(adapter).to receive(:configure_env_vars).with(service: 'myservice', environment_slug: 'myenv', config_dir: '/my/config/dir', system_config: anything).and_return('configure_env_vars_result')
      described_class.configure_env_vars(service: 'myservice', deployment: deployment, environment_slug: 'myenv', config_dir: '/my/config/dir')
    end

    it 'returns the result of configure_env_vars from the adapter' do
      expect(described_class.configure_env_vars(service: 'myimage', deployment: deployment, environment_slug: 'myenv', config_dir: '/my/config/dir')).to eq('configure_env_vars_result')
    end
  end

  describe '.restart' do
    let(:adapter) { double('adapter') }
    let(:service_running) { false }
    let(:deployment_exists) { false }
    before do
      allow(described_class).to receive(:adapter_for).with('myenv').and_return(adapter)
      allow(adapter).to receive(:service_is_running?).and_return(service_running)
      allow(adapter).to receive(:deployment_exists?).and_return(deployment_exists)
      allow(adapter).to receive(:start_service).and_return('start_service_result')
    end

    it 'gets the adapter for the given environment_slug' do
      expect(described_class).to receive(:adapter_for).with('myenv').and_return(adapter)
      described_class.restart(service: 'myservice', environment_slug: 'myenv', tag: 'mytag')
    end

    context 'when the service is running' do
      let(:service_running) { true }

      it 'stops the service' do
        expect(described_class).to receive(:stop_service).with(service: 'myservice', environment_slug: 'myenv')
        described_class.restart(service: 'myservice', environment_slug: 'myenv', tag: 'mytag')
      end
    end

    context 'when the deployment exists' do
      let(:deployment_exists) { true }

      it 'asks the adapter to delete the deployment' do
        expect(adapter).to receive(:delete_deployment).with(service: 'myservice', environment_slug: 'myenv')
        described_class.restart(service: 'myservice', environment_slug: 'myenv', tag: 'mytag')
      end

      context 'if the delete_deployment fails' do
        before do
          allow(adapter).to receive(:delete_deployment).and_raise(CmdFailedError)
        end

        it 'does not throw an exception' do
          expect { described_class.restart(service: 'myservice', environment_slug: 'myenv', tag: 'mytag') }.to_not raise_error
        end
      end
    end

    it 'starts the service' do
      expect(described_class).to receive(:start_service).with(service: 'myservice', environment_slug: 'myenv', tag: 'mytag')
      described_class.restart(service: 'myservice', environment_slug: 'myenv', tag: 'mytag')
    end

    it 'returns the result of start from the adapter' do
      expect(described_class.restart(service: 'myimage', environment_slug: 'myenv', tag: 'mytag')).to eq('start_service_result')
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
      expect(adapter).to receive(:stop_service).with(service: 'myservice', environment_slug: 'myenv').and_return('importedresult')
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
      expect(adapter).to receive(:url_for).with(service: 'myservice', environment_slug: 'myenv').and_return('importedresult')
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
      expect(described_class.empty_deployment(service: service, environment_slug: 'myenv')).to be_a(ServiceDeployment)
    end

    describe 'returned object' do
      let(:returned_object) { described_class.empty_deployment(service: service, environment_slug: 'myenv') }

      it 'has the given service' do
        expect(returned_object.service).to eq(service)
      end

      it 'has the given environment_slug' do
        expect(returned_object.environment_slug).to eq('myenv')
      end
    end
  end
end
