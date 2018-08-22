require 'rails_helper'

describe ServiceConfigParam do
  describe 'validation' do
    let(:name){ 'VALID_NAME' }
    let(:environment_slug){ 'dev' }
    let(:service){ Service.new }
    let(:user){ User.new }
    before do
      subject.service = service
      subject.name = name
      subject.environment_slug = environment_slug
      subject.last_updated_by_user = user
    end

    describe 'an environment_slug' do
      context 'in the list of ServiceEnvironment.all_slugs' do
        let(:environment_slug){ 'staging' }
        it 'is valid' do
          expect(subject.valid?).to eq(true)
        end
      end
      context 'not in the list of ServiceEnvironment.all_slugs' do
        let(:environment_slug){ 'made_up_slug' }
        it 'is invalid' do
          expect(subject.valid?).to eq(false)
        end
      end
      context 'that is blank' do
        let(:environment_slug){ '' }
        it 'is invalid' do
          expect(subject.valid?).to eq(false)
        end
      end
    end
    describe 'a name' do
      context 'of less than 3 characters' do
        let(:name){ 'AB' }
        it 'is invalid' do
          expect(subject.valid?).to eq(false)
        end
      end
      context 'of more than 64 characters' do
        let(:name){ '0123456789ABCDEFG0123456789ABCDEFG0123456789ABCDEFG0123456789ABCDEFG0' }
        it 'is invalid' do
          expect(subject.valid?).to eq(false)
        end
      end
      context 'of 3-64 characters' do
        context 'containing lowercase letters' do
          let(:name){ 'lowercase_letters' }
          it 'is invalid' do
            expect(subject.valid?).to eq(false)
          end
        end
        context 'containing unicode letters' do
          let(:name){ 'CÉDILLE' }
          it 'is invalid' do
            expect(subject.valid?).to eq(false)
          end
        end
        context 'containing spaces' do
          let(:name){ 'THIS IS MY NAME' }
          it 'is invalid' do
            expect(subject.valid?).to eq(false)
          end
        end
        context 'containing only uppercase letters numbers and _' do
          let(:name){ 'THIS_NAME_IS_VALID_1234' }
          it 'is valid' do
            expect(subject.valid?).to eq(true)
          end
        end
      end
    end
  end

  describe '.visible_to' do
    context 'given a user' do
      let(:user) { User.create!(name: 'test user', email: 'test@example.com') }
      let(:other_user) { User.create!(name: 'Other User', email: 'otheruser@example.com') }

      context 'who has created a service' do
        let!(:service_created_by_user) { Service.create!(name: 'test users service', created_by_user: user, git_repo_url: 'https://some.com/repo') }

        context 'with a config param' do
          let!(:user_service_config_param) { ServiceConfigParam.create!(name: 'USER_SERVICE_CONFIG_PARAM', environment_slug: 'dev', value: 'value 1', service: service_created_by_user, last_updated_by_user: user)}

          context 'and a service created by someone else' do
            let!(:service_created_by_other_user) { Service.create!(name: 'other users service', created_by_user: other_user, git_repo_url: 'https://some.com/other/repo') }

            context 'with a config param' do
              let!(:other_user_service_config_param) { ServiceConfigParam.create!(name: 'OTHER_USER_SERVICE_CONFIG_PARAM', environment_slug: 'dev', value: 'value 1', service: service_created_by_other_user, last_updated_by_user: other_user)}

              it 'includes the param from the service created by the given user' do
                expect(ServiceConfigParam.visible_to(user).pluck(:id)).to include(user_service_config_param.id)
              end

              it 'does not include the param from service created by the other user' do
                expect(ServiceConfigParam.visible_to(user).pluck(:id)).to_not include(other_user_service_config_param.id)
              end
            end
          end
        end
      end

      context 'who is a member of a team' do
        let!(:team_with_user_as_member) { Team.create!(name: 'test users team', created_by_user: other_user) }
        before do
          team_with_user_as_member.members << TeamMember.new(user: user, created_by_user: other_user)
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

  describe '#key_value_pairs' do
    let(:indexed) do
      {
        'name1' => double(ServiceConfigParam, name: 'name1', value: 'value1'),
        'name2' => double(ServiceConfigParam, name: 'name2', value: 'value2'),
        'name3' => double(ServiceConfigParam, name: 'name3', value: 'value3')
      }
    end
    context 'given a scope' do
      before do
        allow(scope).to receive(:index_by).and_return(indexed)
      end
      let(:scope) { double('scope') }

      it 'returns all the params in the scope as a hash of name/value pairs' do
        expect(described_class.key_value_pairs(scope)).to eq(
          {
            'name1' => 'value1',
            'name2' => 'value2',
            'name3' => 'value3'
          }
        )
      end
    end
  end
end
