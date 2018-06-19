require 'rails_helper'

class MockController
  attr_accessor :params
  include Concerns::NestedResourceController
  def authorize(*args); end
end
class MockModel
  def self.find_by_my_attr(*args); end
end

describe Concerns::NestedResourceController do
  subject { MockController.new }

  context 'included in a controller' do
    it 'adds a private nest_under method' do
      expect(subject.private_methods).to include(:nest_under)
    end

    it 'adds a private load_and_authorize_parent_resource! class method' do
      expect(subject.private_methods).to include(:load_and_authorize_parent_resource!)
    end

    it 'adds a private load_parent_resource! class method' do
      expect(subject.private_methods).to include(:load_parent_resource!)
    end

    describe '#load_parent_resource!' do
      before do
        subject.params = { my_param: 'my param value' }
        allow(MockModel).to receive(:find_by_my_attr).with('my param value').and_return('foo')
      end

      it 'calls find_by_(attr_name) on the given class, passing params[param_name]' do
        expect(MockModel).to receive(:find_by_my_attr).with('my param value').and_return('foo')
        subject.send(:load_parent_resource!, MockModel, attr_name: 'my_attr', param_name: :my_param)
      end

      it 'returns the result of the find_by_(attr_name) call' do
        return_value = subject.send(:load_parent_resource!, MockModel, attr_name: 'my_attr', param_name: :my_param)
        expect(return_value).to eq('foo')
      end
    end

    describe "#load_and_authorize_parent_resource!" do
      let(:mock_resource){ MockModel.new }
      before do
        allow(subject).to receive(:load_parent_resource!).and_return(mock_resource)
      end

      it 'sets an instance variable called @(resource_name)' do
        expect do
          subject.send(:load_and_authorize_parent_resource!, 'mock_resource', resource_class: MockModel)
        end.to(
          change { subject.send(:instance_variable_get, "@mock_resource") }
                  .from(nil)
                  .to(mock_resource)
        )
      end
    end

    describe '#nest_under' do
      it 'calls load_and_authorize_parent_resource!' do
        expect(subject).to receive(:load_and_authorize_parent_resource!)
        subject.send(:nest_under, :mock_model)
      end

      describe 'passing arguments' do
        let(:args) {{}}

        it 'passes the given resource name' do
          expect(subject).to receive(:load_and_authorize_parent_resource!).with(
            :mock_model,
            anything
          )
          subject.send(:nest_under, :mock_model, args)
        end
        context 'given an :attr_name' do
          let(:args) { {attr_name: 'my_attr'} }
          it 'passes on the given attr_name' do
            expect(subject).to receive(:load_and_authorize_parent_resource!).with(
              :mock_model,
              hash_including(attr_name: 'my_attr')
            )
            subject.send(:nest_under, :mock_model, args)
          end
        end

        context 'given no :attr_name' do
          let(:args) { {} }
          it 'passes attr_name: :id' do
            expect(subject).to receive(:load_and_authorize_parent_resource!).with(
              :mock_model,
              hash_including(attr_name: :id)
            )
            subject.send(:nest_under, :mock_model, args)
          end
        end

        context 'given an :resource_class' do
          let(:args) { {resource_class: 'my resource_class'} }
          it 'passes on the given resource_class' do
            expect(subject).to receive(:load_and_authorize_parent_resource!).with(
              :mock_model,
              hash_including(resource_class: 'my resource_class')
            )
            subject.send(:nest_under, :mock_model, args)
          end
        end

        context 'given no :resource_class' do
          let(:args) { {} }
          it 'derives a resource class from the given resource_name' do
            expect(subject).to receive(:load_and_authorize_parent_resource!).with(
              :mock_model,
              hash_including(resource_class: MockModel)
            )
            subject.send(:nest_under, :mock_model, args)
          end
        end

        context 'given an :param_name' do
          let(:args) { {param_name: 'my param_name'} }
          it 'passes on the given param_name' do
            expect(subject).to receive(:load_and_authorize_parent_resource!).with(
              :mock_model,
              hash_including(param_name: 'my param_name')
            )
            subject.send(:nest_under, :mock_model, args)
          end
        end

        context 'given no :param_name' do
          let(:args) { {} }
          it 'derives param_name from (resource_name)_id' do
            expect(subject).to receive(:load_and_authorize_parent_resource!).with(
              :mock_model,
              hash_including(param_name: 'mock_model_id')
            )
            subject.send(:nest_under, :mock_model, args)
          end
        end
      end
    end
  end


end
