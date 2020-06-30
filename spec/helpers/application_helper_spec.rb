require 'rails_helper'

class MockController
  attr_accessor :current_user, :params
  include ApplicationHelper
end

describe ApplicationHelper do
  let(:mock_controller) { MockController.new }
  let(:mock_user){ instance_double(User) }

  before do
    mock_controller.current_user = mock_user
  end

  describe '#can?' do
    let(:service){ Service.new }
    let(:mock_policy){ instance_double(ServicePolicy, show?: result) }
    let(:result) { 'show? result' }

    before do
      allow(ServicePolicy).to receive(:new).with(mock_user, service).and_return(mock_policy)
      allow(mock_policy).to receive(:show?).and_return(result)
    end

    it 'creates a policy for the given object & current_user' do
      expect(ServicePolicy).to receive(:new).with(mock_user, service).and_return(mock_policy)
      mock_controller.can?(:show, service)
    end

    it 'calls (action)? on the object policy' do
      expect(mock_policy).to receive(:show?).and_return(result)
      mock_controller.can?(:show, service)
    end

    it 'returns the result of calling (action)? on the object policy' do
      expect(mock_controller.can?(:show, service)).to eq(result)
    end
  end

  describe 'form_environment' do
    context 'given a valid environment slug' do
      let(:slug) { 'dev' }

      it 'returns the name of the given environment' do
        expect(mock_controller.form_environment(slug)).to eq('Test')
      end

      context 'as a symbol' do
        let(:slug) { :dev }

        it 'returns the name of the given environment' do
          expect(mock_controller.form_environment(slug)).to eq('Test')
        end
      end
    end

    context 'given an invalid environment slug' do
      let(:slug) { 'something non-existent' }
      it 'returns nil' do
        expect(mock_controller.form_environment(slug)).to be_nil
      end
    end
  end

  describe '#update_or_create' do
    context 'given a model' do
      let(:model) { double('model', persisted?: persisted) }

      context 'that is persisted' do
        let(:persisted) { true }
        it 'returns {action: :update}' do
          expect(mock_controller.update_or_create(model)).to eq({action: :update})
        end
      end
      context 'that is not persisted' do
        let(:persisted) { false }
        it 'returns {action: :create}' do
          expect(mock_controller.update_or_create(model)).to eq({action: :create})
        end
      end
    end
  end

  describe '#current_action?' do
    before do
      mock_controller.params = params
    end

    context 'given a controller name' do
      let(:controller_name) { 'services/deployments' }

      context 'and no action' do
        context 'when the controller does not match params' do
          let(:params) {
            {controller: :some_other_controller, action: nil}
          }

          it 'returns false' do
            expect(mock_controller.current_action?(controller: controller_name)).to eq(false)
          end
        end

        context 'when the controller does match params' do
          let(:params) {
            {controller: controller_name, action: :some_other_action}
          }

          it 'returns true' do
            expect(mock_controller.current_action?(controller: controller_name)).to eq(true)
          end
        end
      end

      context 'and an action' do
        let(:action) { :show }

        context 'when the controller and action both match params' do
          let(:params) {
            {controller: controller_name, action: action}
          }

          it 'returns true' do
            expect(mock_controller.current_action?(controller: controller_name, action: action)).to eq(true)
          end
        end

        context 'when the action does not match params' do
          let(:params) {
            {controller: controller_name, action: :some_other_action}
          }

          it 'returns false' do
            expect(mock_controller.current_action?(controller: controller_name, action: action)).to eq(false)
          end
        end

        context 'when the controller does not match params' do
          let(:params) {
            {controller: :some_other_controller, action: action}
          }

          it 'returns false' do
            expect(mock_controller.current_action?(controller: controller_name, action: action)).to eq(false)
          end
        end
      end
    end
  end
end
