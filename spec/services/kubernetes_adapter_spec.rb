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
                                  config_map_name: nil
                                 )

        hash = YAML.load(File.open(config_dir.join(filename)).read)
        value = hash.dig('spec', 'template', 'spec', 'containers', 0, 'env').find{|k,v| k['name'] == 'USER_DATASTORE_URL' }['value']
        expect(value).to eql('http://fb-user-datastore-api-svc--dev.formbuilder-platform--dev/')
      end
    end
  end
end
