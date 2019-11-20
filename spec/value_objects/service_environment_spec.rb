require 'rails_helper'

describe ServiceEnvironment do
  describe '.all_slugs' do
    it 'has all slugs from Rails.configuration.x.service_environments' do
      expect(described_class.all_slugs).to eq([:dev, :production])
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
      let(:slug) { :dev }

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
    subject do
      ServiceEnvironment.new(protocol: 'myprotocol://',
                             url_root: 'test.form.service.justice.gov.uk',
                             slug: 'dev')
    end

    context 'given a service' do
      let(:service){ Service.new(slug: 'ioj')}

      it 'returns a string combining the protocol, slug+env, and url_root, ending with a slash' do
        expect(subject.url_for(service)).to eq('myprotocol://ioj.dev.test.form.service.justice.gov.uk/')
      end
    end

    context 'when dev-live' do
      subject do
        ServiceEnvironment.new(protocol: 'myprotocol://',
                               url_root: 'form.service.justice.gov.uk',
                               slug: 'dev')
      end

      let(:service){ Service.new(slug: 'ioj')}

      it 'returns a string combining the protocol, slug+env, and url_root, ending with a slash' do
        expect(subject.url_for(service)).to eq('myprotocol://ioj.dev.form.service.justice.gov.uk/')
      end
    end

    context 'when production-live' do
      subject do
        ServiceEnvironment.new(protocol: 'myprotocol://',
                               url_root: 'form.service.justice.gov.uk',
                               slug: 'production')
      end

      let(:service){ Service.new(slug: 'ioj')}

      it 'returns a string combining the protocol, slug+env, and url_root, ending with a slash' do
        expect(subject.url_for(service)).to eq('myprotocol://ioj.form.service.justice.gov.uk/')
      end
    end
  end

  describe '.name_of' do
    context 'given a slug' do
      context 'that is a sym which exists' do
        let(:slug){ :dev }
        it 'returns the name of the matching environment' do
          expect(described_class.name_of(slug)).to eq('Development')
        end
      end
      context 'that is a string which exists' do
        let(:slug){ 'dev' }
        it 'returns the name of the matching environment' do
          expect(described_class.name_of(slug)).to eq('Development')
        end
      end
      context 'that does not exist' do
        let(:slug){ 'made up slug' }
        it 'returns nil' do
          expect(described_class.name_of(slug)).to be_nil
        end
      end
    end
  end
end
