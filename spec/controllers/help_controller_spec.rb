require 'rails_helper'

describe HelpController do
  describe '#show' do
    context 'for any user, signed in or not' do
      it 'returns 200 OK' do
        get :show
        expect(response.status).to eq(200)
      end
    end
  end
end
