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
  end
end
