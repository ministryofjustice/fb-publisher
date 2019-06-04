require 'rails_helper'

describe ServicesController do
  let(:user) { User.create!(name: 'user', email: 'user@example.com') }

  before do
    session[:user_id] = user.try(:id)
    controller.send(:instance_variable_set, "@current_user", user)
  end

  describe '#index' do
    context 'for a logged-in user' do
      let(:user_services) do
        [
          Service.create!(name: 'service 1', git_repo_url: 'https://some/repo/1', created_by_user_id: user.id),
          Service.create!(name: 'service 2', git_repo_url: 'https://some/repo/2', created_by_user_id: user.id)
        ]
      end

      it 'returns 200 OK' do
        get :index
        expect(response.status).to eq(200)
      end

      it 'retrieves services visible_to that user' do
        expect(ServicePolicy.new(user, user_services).record).to eq(user_services)
        get :index
      end
    end

    context 'for a user who is not logged-in' do
      let(:user){ nil }

      it 'redirects to root path' do
        get :index
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'POST #create' do
    let(:do_post!) do
      post :create, params: { service: { git_repo_url: 'https://github.com/ministryofjustice/fb-ioj', name: 'ioj', deploy_key: 'private_key' } }
    end

    it 'persists the service' do
      expect do
        do_post!
      end.to change(Service, :count).by(1)
    end

    it 'persist correct values' do
      do_post!
      service = Service.last

      expect(service.git_repo_url).to eql('https://github.com/ministryofjustice/fb-ioj')
      expect(service.name).to eql('ioj')
      expect(service.deploy_key).to eql('private_key')
    end
  end
end
