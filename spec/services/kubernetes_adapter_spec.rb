require 'rails_helper'

describe KubernetesAdapter do
  describe '#create_secret' do
    subject { described_class.new(environment: ServiceEnvironment.find(:dev)) }

    before :each do
      allow(subject).to receive(:apply_file)
    end

    it 'create secret within yaml file' do
      subject.create_secret(name: 'foo', key_ref: 'bar', value: 'baz', config_dir: '/tmp')

      hash = YAML.load(File.open('/tmp/service-token-secret.yml').read)
      expect(hash['data']).to eql({'bar' => 'YmF6'})
    end

    describe '#deployment' do
      before :each do
        FileUtils.rm_f(config_dir.join(filename))
      end

      let(:config_dir) { Pathname.new('/tmp') }
      let(:filename) { 'deployment.yml' }

      it 'sets env variable USER_DATASTORE_URL' do
        subject.create_deployment(config_dir: config_dir,
                                  name: nil,
                                  container_port: nil,
                                  image: nil,
                                  json_repo: nil,
                                  commit_ref: nil,
                                  config_map_name: nil,
                                  service: Service.new
                                 )

        hash = YAML.load(File.open(config_dir.join(filename)).read)
        value = hash.dig('spec', 'template', 'spec', 'containers', 0, 'env').find{|k,v| k['name'] == 'USER_DATASTORE_URL' }['value']
        expect(value).to eql('http://fb-user-datastore-api-svc--dev.formbuilder-platform--dev/')
      end

      it 'sets env variable PLATFORM_ENV' do
        allow(ENV).to receive(:[]).with('PLATFORM_ENV').and_return('test')

        subject.create_deployment(config_dir: config_dir,
                                  name: nil,
                                  container_port: nil,
                                  image: nil,
                                  json_repo: nil,
                                  commit_ref: nil,
                                  config_map_name: nil,
                                  service: Service.new
                                 )

        hash = YAML.load(File.open(config_dir.join(filename)).read)
        value = hash.dig('spec', 'template', 'spec', 'containers', 0, 'env').find{|k,v| k['name'] == 'PLATFORM_ENV' }['value']
        expect(value).to eql('test')
      end

      it 'sets env variable DEPLOYMENT_ENV' do
        subject.create_deployment(config_dir: config_dir,
                                  name: nil,
                                  container_port: nil,
                                  image: nil,
                                  json_repo: nil,
                                  commit_ref: nil,
                                  config_map_name: nil,
                                  service: Service.new
                                 )

        hash = YAML.load(File.open(config_dir.join(filename)).read)
        value = hash.dig('spec', 'template', 'spec', 'containers', 0, 'env').find{|k,v| k['name'] == 'DEPLOYMENT_ENV' }['value']
        expect(value).to eql('dev')
      end

      context do
        let(:service_env) do
          ServiceEnvironment.new(slug: :dev,
                                 url_root: 'test.form.service.justice.gov.uk',
                                 protocol: 'https://')
        end

        subject { described_class.new(environment: service_env) }

        it 'sets env var FROM_URL' do
          subject.create_deployment(config_dir: config_dir,
                                    name: nil,
                                    container_port: nil,
                                    image: nil,
                                    json_repo: nil,
                                    commit_ref: nil,
                                    config_map_name: nil,
                                    service: Service.new(slug: 'contact')
                                   )

          hash = YAML.load(File.open(config_dir.join(filename)).read)
          value = hash.dig('spec', 'template', 'spec', 'containers', 0, 'env').find{|k,v| k['name'] == 'FORM_URL' }['value']
          expect(value).to eql('https://contact.dev.test.form.service.justice.gov.uk')
        end
      end
    end
  end
end
