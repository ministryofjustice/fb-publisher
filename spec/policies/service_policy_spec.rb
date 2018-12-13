require 'rails_helper'

describe ServicePolicy do
  let(:user) { User.create!(name: 'my user') }
  let(:another_user) { User.create!(name: 'another user') }
  let(:service) { Service.create!(name: 'Test Service', git_repo_url: 'https://some-repo.git', created_by_user: user) }
  let(:admin_user) { User.create!(name: 'admin user') }
  let(:admin_team) { Team.create!(name: 'Admin', super_admin: true, created_by_user: admin_user) }

  before do
    admin_team.members.create!(user: admin_user, created_by_user: admin_user)
  end

  subject(:admin) { ApplicationPolicy.new(admin_user, nil).policy_for(service) }
  subject(:non_admin) { ApplicationPolicy.new(another_user, nil).policy_for(service) }
  subject(:creator) { ApplicationPolicy.new(user, nil).policy_for(service) }

  describe 'is_editable_by?' do
    describe 'for a service created by a non-admin' do
      it 'is editable by the super_admin user' do
        expect(admin.send(:is_editable_by?, admin_user.id)).to eq(true)
      end

      it 'is not editable by another non-admin non-team-member user' do
        expect(non_admin.send(:is_editable_by?, another_user.id)).to eq(false)
      end

      it 'is editable by the user who created it' do
        expect(creator.send(:is_editable_by?, user.id)).to eq(true)
      end
    end
  end

  describe 'scope' do
    describe 'for a service not created by an admin' do
      it 'is available to the admin to access' do
        expect(admin.scope).to include(service)
      end
    end

    describe 'for a service created by the user' do
      it 'is available to the user to access' do
        expect(creator.scope).to include(service)
      end
    end

    describe 'for a service not created by a user who is not an admin' do
      it 'is not available to the user to access' do
        expect(non_admin.scope).not_to include(service)
      end
    end
  end
end
