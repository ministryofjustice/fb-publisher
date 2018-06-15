require 'rails_helper'

# dummy controller to include the helper
class MockController
  attr_accessor :session
  attr_writer :current_user

  include Auth0Helper

  def initialize(params = {})
    @session = params[:session]
    @current_user = params[:current_user]
  end

  # mock method as it's called in the helper
  def redirect_to(args)
  end

  def root_path
    'login path'
  end
end

describe Auth0Helper do
  let(:params) { {} }
  subject { MockController.new(params) }

  describe '#user_signed_in?' do
    context 'when session[:user_id] is present' do
      before do
        params[:session] = { user_id: 1234 }
      end

      it 'returns true' do
        expect(subject.send(:user_signed_in?)).to eq(true)
      end
    end

    context 'when session[:user_id] is not present' do
      before do
        params[:session] = nil
      end

      it 'returns false' do
        expect(subject.send(:user_signed_in?)).to eq(false)
      end
    end
  end

  describe '#identify_user' do
    before do
      params[:session] = { user_id: 'session user_id' }
    end
    context 'when the user is signed in' do
      before do
        allow(subject).to receive(:user_signed_in?).and_return(true)
      end

      context 'and there is already a @current_user' do
        before do
          subject.current_user = 'existing current_user'
        end

        it 'returns the existing current_user' do
          expect(subject.send(:identify_user)).to eq('existing current_user')
        end
      end

      context 'and there is no existing @current_user' do
        let(:mock_user){ double(User) }

        it 'gets the User with id matching session[:user_id]' do
          expect(User).to receive(:where).with(id: 'session user_id').and_return([mock_user])
          subject.send(:identify_user)
        end

        context 'when a matching user is found' do
          before do
            allow(User).to receive(:where).and_return([mock_user])
          end
          it 'stores the matching user in @current_user' do
            subject.send(:identify_user)
            expect(subject.current_user).to eq(mock_user)
          end
          it 'returns the matching user' do
            expect(subject.send(:identify_user)).to eq(mock_user)
          end
        end
        context 'when no matching user is found' do
          before do
            allow(User).to receive(:where).and_return([])
          end

          it 'returns nil' do
            expect(subject.send(:identify_user)).to eq(nil)
          end
          it 'sets @current_user to nil' do
            subject.send(:identify_user)
            expect(subject.current_user).to eq(nil)
          end
        end
      end
    end

    context 'when the user is not signed in' do
      it 'returns nil' do
        expect(subject.send(:identify_user)).to eq(nil)
      end
      it 'does not change current_user' do
        expect {subject.send(:identify_user)}.to_not change(subject, :current_user)
      end
    end
  end

  describe '#require_user!' do
    context 'when the user is signed in' do
      before do
        allow(subject).to receive(:user_signed_in?).and_return(true)
      end
      it 'calls identify_user' do
        expect(subject).to receive(:identify_user)
        subject.send(:require_user!)
      end
    end
    context 'when the user is not signed in' do
      before do
        allow(subject).to receive(:user_signed_in?).and_return(false)
      end

      it 'redirects to login_path' do
        expect(subject).to receive(:redirect_to).with('login path')
        subject.send(:require_user!)
      end
    end
  end

  describe '#current_user' do
    it 'returns the value of @current_user' do
      subject.current_user='blah'
      expect(subject.current_user).to eq('blah')
    end
  end
end
