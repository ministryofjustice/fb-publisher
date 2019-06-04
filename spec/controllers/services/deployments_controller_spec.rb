require 'rails_helper'

describe Services::DeploymentsController do
  let(:user) { User.create!(name: 'user', email: 'user@example.com') }
  let(:service) do
    Service.create!(name: 'service 1', git_repo_url: 'https://some/repo/1', created_by_user_id: user.id)
  end

  before do
    session[:user_id] = user.try(:id)
    controller.send(:instance_variable_set, "@current_user", user)
  end

  describe 'GET #index' do
    it 'returns 200 OK' do
      get :index, params: { service_slug: service.slug, controller_name: :service_deployments }
      expect(response.status).to eq(200)
    end
  end

  describe 'POST #create' do
    let(:do_post!) do
      post :create, params: { service_slug: service.slug,
                              controller_name: :service_deployments,
                              service_deployment: {
                                environment_slug: 'dev',
                                service_id: service.id,
                                json_sub_dir: 'sub/dir',
                                commit_sha: 'sha123'
                              }
                            }
    end

    it 'persists a ServiceDeployment' do
      expect do
        do_post!
      end.to change(ServiceDeployment, :count).by(1)
    end

    it 'save with passed params' do
      do_post!
      record = ServiceDeployment.last
      expect(record.json_sub_dir).to eql('sub/dir')
      expect(record.commit_sha).to eql('sha123')
    end
  end
end
