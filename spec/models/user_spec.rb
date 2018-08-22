require 'rails_helper'

describe User do
  let(:user) { User.create!(name: 'test user', email: 'test@example.com') }

  describe '.visible_to' do
    context 'given a user' do
      describe 'any other user' do
        let!(:other_user) { User.create!(name: 'Other User', email: 'otheruser@example.com') }

        it 'is included' do
          expect(User.visible_to(user).pluck(:id)).to include(other_user.id)
        end
      end
    end
  end

  describe '#name_and_email' do
    it 'returns the users name followed by the email in brackets' do
      expect(user.name_and_email).to eq('test user (test@example.com)')
    end
  end
end
