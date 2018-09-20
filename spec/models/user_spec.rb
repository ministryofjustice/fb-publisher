require 'rails_helper'

describe User do
  let(:user) { User.new(name: 'test user', email: 'test@example.com') }

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
end
