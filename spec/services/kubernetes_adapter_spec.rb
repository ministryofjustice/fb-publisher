require 'rails_helper'

describe KubernetesAdapter do
  describe '#create_secret' do
    subject { described_class.new(environment: service_environment) }

    let(:service_environment) do
      se = ServiceEnvironment.find(:dev)
      allow(se).to receive(:namespace).and_return('formbuilder-services-test-dev')
      se
    end

    before :each do
      allow(subject).to receive(:apply_file)
    end

    it 'create secret within yaml file' do
      subject.create_secret(name: 'foo', key_ref: 'bar', value: 'baz', config_dir: '/tmp')

      hash = YAML.load(File.open('/tmp/service-token-secret.yml').read)
      expect(hash['data']).to eql({'bar' => 'YmF6'})
    end

    describe '#create_deployment' do
      before :each do
        FileUtils.rm_f(config_dir.join(filename))
      end

      let(:config_dir) { Pathname.new('/tmp') }
      let(:filename) { 'deployment.yml' }
      let(:service) { Service.new }

      let(:create_deployment) do
        subject.create_deployment(config_dir: config_dir,
                                  name: nil,
                                  container_port: nil,
                                  image: nil,
                                  json_repo: nil,
                                  commit_ref: nil,
                                  config_map_name: nil,
                                  service: service)
      end

      it 'sets env variable USER_DATASTORE_URL' do
        create_deployment

        hash = YAML.load(File.open(config_dir.join(filename)).read)
        value = hash.dig('spec', 'template', 'spec', 'containers', 0, 'env').find{|k,v| k['name'] == 'USER_DATASTORE_URL' }['value']
        expect(value).to eql('http://fb-user-datastore-api-svc--dev.formbuilder-platform--dev/')
      end

      it 'sets env variable PLATFORM_ENV' do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('PLATFORM_ENV').and_return('test')

        create_deployment

        hash = YAML.load(File.open(config_dir.join(filename)).read)
        value = hash.dig('spec', 'template', 'spec', 'containers', 0, 'env').find{|k,v| k['name'] == 'PLATFORM_ENV' }['value']
        expect(value).to eql('test')
      end

      it 'sets env variable DEPLOYMENT_ENV' do
        create_deployment

        hash = YAML.load(File.open(config_dir.join(filename)).read)
        value = hash.dig('spec', 'template', 'spec', 'containers', 0, 'env').find{|k,v| k['name'] == 'DEPLOYMENT_ENV' }['value']
        expect(value).to eql('dev')
      end

      it 'sets SENTRY_DSN for form' do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('RUNNER_SENTRY_DSN')
                                  .and_return('runner-sentry-dsn-here')

        create_deployment

        hash = YAML.load(File.open(config_dir.join(filename)).read)
        value = hash.dig('spec', 'template', 'spec', 'containers', 0, 'env')
                    .find{|k,v| k['name'] == 'SENTRY_DSN' }['value']
        expect(value).to eql('runner-sentry-dsn-here')
      end

      it 'sets default resources' do
        create_deployment

        hash = YAML.load(File.open(config_dir.join(filename)).read)
        hash = hash.dig('spec', 'template', 'spec', 'containers', 0, 'resources')

        expect(hash).to eql({ "limits" => { "cpu" => "150m", "memory" => "300Mi" },
                              "requests" => { "cpu" => "10m", "memory" => "128Mi" }})
      end

      context do
        let(:service) { create(:service) }

        before :each do
          service.service_config_params << ServiceConfigParam.create!(service: service,
                                                            name: 'RESOURCES_LIMITS_CPU', value: '300m',
                                                            environment_slug: 'dev',
                                                            last_updated_by_user: service.created_by_user)

          service.service_config_params << ServiceConfigParam.create!(service: service,
                                                            name: 'RESOURCES_LIMITS_MEMORY', value: '600Mi',
                                                            environment_slug: 'dev',
                                                            last_updated_by_user: service.created_by_user)

          service.service_config_params << ServiceConfigParam.create!(service: service,
                                                            name: 'RESOURCES_REQUESTS_CPU', value: '20m',
                                                            environment_slug: 'dev',
                                                            last_updated_by_user: service.created_by_user)

          service.service_config_params << ServiceConfigParam.create!(service: service,
                                                            name: 'RESOURCES_REQUESTS_MEMORY', value: '256Mi',
                                                            environment_slug: 'dev',
                                                            last_updated_by_user: service.created_by_user)
        end

        it 'can have custom resourcing' do
          create_deployment

          hash = YAML.load(File.open(config_dir.join(filename)).read)
          hash = hash.dig('spec', 'template', 'spec', 'containers', 0, 'resources')

          expect(hash).to eql({ "limits" => { "cpu" => "300m", "memory" => "600Mi" },
                                "requests" => { "cpu" => "20m", "memory" => "256Mi" }})
        end
      end

      it 'sets default replicas' do
        create_deployment

        hash = YAML.load(File.open(config_dir.join(filename)).read)
        replicas = hash.dig('spec', 'replicas')

        expect(replicas).to eql(2)
      end

      context do
        let(:service) { create(:service) }

        before :each do
          service.service_config_params << ServiceConfigParam.create!(service: service,
                                                            name: 'DEPLOYMENT_REPLICAS',
                                                            value: '4',
                                                            environment_slug: 'dev',
                                                            last_updated_by_user: service.created_by_user)
        end

        it 'have custom number of replicas' do
          create_deployment

          hash = YAML.load(File.open(config_dir.join(filename)).read)
          replicas = hash.dig('spec', 'replicas')

          expect(replicas).to eql(4)
        end
      end

      context do
        let(:service_env) do
          ServiceEnvironment.new(slug: :dev,
                                 url_root: 'test.form.service.justice.gov.uk',
                                 protocol: 'https://')
        end

        let(:service) { Service.new(slug: 'contact') }

        subject { described_class.new(environment: service_env) }

        it 'sets env var FROM_URL' do
          create_deployment

          hash = YAML.load(File.open(config_dir.join(filename)).read)
          value = hash.dig('spec', 'template', 'spec', 'containers', 0, 'env').find{|k,v| k['name'] == 'FORM_URL' }['value']
          expect(value).to eql('https://contact.dev.test.form.service.justice.gov.uk')
        end
      end
    end

    describe '#create_service' do
      let(:config_dir) { Pathname.new('/tmp') }
      let(:filename) { 'service.yml' }
      let(:service) { Service.new(slug: 'service-slug') }

      before :each do
        FileUtils.rm_f(config_dir.join(filename))
      end

      it 'writes service.yaml' do
        subject.create_service(config_dir: config_dir,
                               service: service)

        expect(File.exists?(config_dir.join(filename)))
      end

      it 'generates correct service.yaml' do
        subject.create_service(config_dir: config_dir,
                               service: service)

        hash = YAML.load(File.open(config_dir.join(filename)).read)

        expect(hash.dig('kind')).to eql('Service')

        expect(hash.dig('metadata', 'labels', 'run')).to eql('service-slug')
        expect(hash.dig('metadata', 'name')).to eql('service-slug')
        expect(hash.dig('metadata', 'namespace')).to eql('formbuilder-services-test-dev')

        expect(hash.dig('spec', 'ports', 0, 'name')).to eql('http')
        expect(hash.dig('spec', 'ports', 0, 'port')).to eql(3000)
        expect(hash.dig('spec', 'ports', 0, 'protocol')).to eql('TCP')
        expect(hash.dig('spec', 'ports', 0, 'targetPort')).to eql(3000)
        expect(hash.dig('spec', 'selector', 'run')).to eql('service-slug')
      end

      it 'calls apply file' do
        expect(subject).to receive(:apply_file)

        subject.create_service(config_dir: config_dir,
                               service: service)
      end
    end
  end
end
