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
end
