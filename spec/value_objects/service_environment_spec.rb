require 'rails_helper'

describe ServiceEnvironment do
  describe '.all_slugs' do
    it 'has all slugs from Rails.configuration.x.service_environments' do
      expect(described_class.all_slugs).to eq([:dev, :staging, :production])
    end
  end

  describe '.where' do
    context 'given some attribute: value pairs' do
      let(:args) { {protocol: 'https://'} }
      let(:values){ described_class.where(args) }

      it 'returns all values where all attributes match' do
        expect(values.map(&:protocol)).to eq(['https://', 'https://'])
      end
    end
  end

  describe '.find' do
    context 'given a slug' do
      let(:slug) { :staging }
      it 'returns the environment with matching slug' do
        expect(described_class.find(slug).slug).to eq(slug)
      end
    end
  end

  describe '#to_h' do
    subject { ServiceEnvironment.new(protocol: 'my protocol', name: 'my name') }
    it 'is a hash' do
      expect(subject.to_h).to be_a(Hash)
    end
    it 'has values populated' do
      expect(subject.to_h).to include(protocol: 'my protocol', name: 'my name')
    end
  end

  describe '#url_for' do
    subject { ServiceEnvironment.new(protocol: 'myprotocol://', url_root:'root.host.name') }

    context 'given a service' do
      let(:service){ Service.new(slug: 'my-service-slug')}

      it 'returns a string combining the protocol, slug, and url_root, ending with a slash' do
        expect(subject.url_for(service)).to eq('myprotocol://my-service-slug.root.host.name/')
      end
    end
  end
end
