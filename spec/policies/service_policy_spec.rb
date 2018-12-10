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

  describe 'is_editable_by?' do
    describe 'for a service created by a non-admin' do
      it 'is editable by the super_admin user' do
        expect(admin.send(:is_editable_by?, admin_user.id)).to eq(true)
      end

      it 'is not editable by another non-admin non-team-member user' do
        expect(non_admin.send(:is_editable_by?, another_user.id)).to eq(false)
      end
    end
  end
end
