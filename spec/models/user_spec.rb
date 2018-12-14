require 'rails_helper'

describe User do
  let(:user) { User.create!(name: 'test user', email: 'test@example.com') }

  describe '#name_and_email' do
    it 'is of the form {name} "({email})"' do
      expect(user.name_and_email).to eq('test user (test@example.com)')
    end
  end

  describe 'has_identity?' do
    let(:identity) { Identity.new(uid: 'myuid', provider: 'myprovider') }

    context 'when no identity exists with the given uid & provider' do
      it 'returns true' do
        expect(user.has_identity?(identity)).to eq(false)
      end
    end
    context 'when an identity exists with the given uid & provider' do
      before do
        user.identities << identity
      end

      it 'returns true' do
        expect(user.has_identity?(identity)).to eq(true)
      end
    end
  end

  describe 'super_admin?' do
    describe 'when user is not a member of super_admin' do
      it 'returns false' do
        expect(user.super_admin?).to eq(false)
      end
    end

    context 'when user is a member of the super_admin team' do
      let(:admin_team) do
        Team.create!(name: 'Super Admin', created_by_user_id: user.id, super_admin: true)
      end

      before do
        TeamMember.create!(user_id: user.id, team_id: admin_team.id, created_by_user_id: user.id)
      end

      it 'returns true' do
        expect(user.super_admin?).to eq(true)
      end
    end
  end
end
