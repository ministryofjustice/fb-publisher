require 'rails_helper'

describe Team do
  describe '.visible_to' do
    context 'given a user' do
      let(:user) { User.create!(name: 'test user', email: 'test@example.com') }
      let(:other_user) { User.create(name: 'Other User', email: 'otheruser@example.com') }

      context 'who has created a team' do
        let!(:team_created_by_user) { Team.create!(name: 'test users team', created_by_user: user) }

        context 'and a team created by someone else' do
          let!(:team_created_by_other_user) { Team.create!(name: 'other users team', created_by_user: other_user) }

          it 'includes the team created by the given user' do
            expect(Team.visible_to(user).pluck(:id)).to include(team_created_by_user.id)
          end

          it 'does not include the team created by the other user' do
            expect(Team.visible_to(user).pluck(:id)).to_not include(team_created_by_other_user.id)
          end
        end
      end

      context 'who is a member of a team' do
        let!(:team_with_user_as_member) { Team.create!(name: 'test users team', created_by_user: other_user) }
        before do
          team_with_user_as_member.users_as_member << user
        end

        it 'includes the team with the given user as member' do
          expect(Team.visible_to(user).pluck(:id)).to include(team_with_user_as_member.id)
        end

        context 'and a team of which they are not a member' do
          let(:team_without_user_as_member) { Team.create(name: 'team without user as member', created_by_user: other_user) }

          it 'does not include the team of which they are not a member' do
            expect(Team.visible_to(user).pluck(:id)).to_not include(team_without_user_as_member.id)
          end
        end
      end
    end
  end
end
