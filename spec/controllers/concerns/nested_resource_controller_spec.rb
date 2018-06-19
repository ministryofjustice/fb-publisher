require 'rails_helper'

class MockController
  attr_accessor :params
  include Concerns::NestedResourceController

  def authorize(*args); end
  def self.before_action(*args); end
end
class MockModel
  def self.find_by_my_attr(*args); end
end

describe Concerns::NestedResourceController do
  subject { MockController.new }

  context 'included in a controller' do
    it 'adds a nest_under class method' do
      expect(MockController).to respond_to(:nest_under)
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
          subject.send(:load_and_authorize_parent_resource!, resource_name: 'mock_resource', resource_class: MockModel)
        end.to(
          change { subject.send(:instance_variable_get, "@mock_resource") }
                  .from(nil)
                  .to(mock_resource)
        )
      end
    end

    describe '#nest_under' do
      it 'calls before_action with :load_and_authorize_parent_resource!' do
        expect(MockController).to receive(:before_action).with(:load_and_authorize_parent_resource!)
        MockController.send(:nest_under, :mock_model)
      end

      it 'sets @nested_resource_options on the class' do
        MockController.send(:nest_under, :mock_model)
        expect(MockController.send(:instance_variable_get, '@nested_resource_options')).to_not be_nil
      end

      describe 'the stored @nested_resource_options' do
        let(:args) {{}}
        let(:stored_options){ MockController.send(:instance_variable_get, '@nested_resource_options') }

        it 'includes the given resource name' do
          MockController.send(:nest_under, :mock_model, args)
          expect(stored_options[:resource_name]).to eq(:mock_model)
        end
        context 'given an :attr_name' do
          let(:args) { {attr_name: 'my_attr'} }
          it 'passes on the given attr_name' do
            MockController.send(:nest_under, :mock_model, args)
            expect(stored_options[:attr_name]).to eq('my_attr')
          end
        end

        context 'given no :attr_name' do
          let(:args) { {} }
          it 'passes attr_name: :id' do
            MockController.send(:nest_under, :mock_model, args)
            expect(stored_options[:attr_name]).to eq(:id)
          end
        end

        context 'given an :resource_class' do
          let(:args) { {resource_class: 'my resource_class'} }
          it 'passes on the given resource_class' do
            MockController.send(:nest_under, :mock_model, args)
            expect(stored_options[:resource_class]).to eq('my resource_class')
          end
        end

        context 'given no :resource_class' do
          let(:args) { {} }
          it 'derives a resource class from the given resource_name' do
            MockController.send(:nest_under, :mock_model, args)
            expect(stored_options[:resource_class]).to eq(MockModel)
          end
        end

        context 'given an :param_name' do
          let(:args) { {param_name: 'my param_name'} }
          it 'passes on the given param_name' do
            MockController.send(:nest_under, :mock_model, args)
            expect(stored_options[:param_name]).to eq('my param_name')
          end
        end

        context 'given no :param_name' do
          let(:args) { {} }
          it 'derives param_name from (resource_name)_id' do
            MockController.send(:nest_under, :mock_model, args)
            expect(stored_options[:param_name]).to eq('mock_model_id')
          end
        end
      end
    end
  end


end
