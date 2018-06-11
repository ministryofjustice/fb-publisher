require 'rails_helper'

describe Auth0UserSession do
  describe 'validation' do
    context 'when the userinfo -> email ends in justice.gov.uk' do
      before do
        subject.user_info = {
          'info' => {
            'email' => 'test-only@some-agency.justice.gov.uk'
          }
        }
      end

      it 'is valid' do
        expect(subject).to be_valid
      end
    end

    context 'when the userinfo -> email does not end in justice.gov.uk' do
      before do
        subject.user_info = {
          'info' => {
            'email' => 'test-only@some-agency.defra.gov.uk'
          }
        }
      end

      it 'is not valid' do
        expect(subject).to_not be_valid
      end
    end
  end

  describe 'save_to' do
    let(:user_info){
      {
        'info' => {
          'email' => 'test-only@some-agency.defra.gov.uk',
          'name' => 'Example McUser'
        }
      }
    }
    subject do
      described_class.new(user_id: 1234, user_info: user_info)
    end
    context 'given a hash' do
      let(:session){ {} }
      before do
        subject.save_to(session)
      end

      it 'saves the user_id to the given hash' do
        expect(session[:user_id]).to eq(subject.user_id)
      end

      it 'sets created_at to now' do
        expect(session[:created_at]).to be_within(100).of(Time.now.to_i)
      end
    end
  end
end
