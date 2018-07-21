require 'rails_helper'

describe TeamsController do
  before do
    session[:user_id] = user.try(:id)
    controller.send(:instance_variable_set, "@current_user", user)
  end

  describe '#index' do
    context 'for a logged-in user' do
      let(:user) { User.create(name: 'user 1', email: 'user@example.com') }
      let(:user_services)  do
        [
          Team.create!(name: 'team 1', created_by_user_id: user.id),
          Team.create!(name: 'team 2', created_by_user_id: user.id)
        ]
      end

      it 'returns 200 OK' do
        get :index
        expect(response.status).to eq(200)
      end

      it 'retrieves services visible_to that user' do
        expect(Team).to receive(:visible_to).with(user).and_return(user_services)
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
end
