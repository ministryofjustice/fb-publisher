require 'rails_helper'

RSpec.describe PublicPrivateKey do
  describe '#public_key' do
    it 'generates a public_key' do
      expect(subject.public_key).to be_present
    end
  end

  describe '#private_key' do
    it 'generates a private_key' do
      expect(subject.private_key).to be_present
    end
  end
end
