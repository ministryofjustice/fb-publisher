require 'rails_helper'

describe TeamPolicy do
  let(:user) { User.new(name: 'my user') }
  let(:team) { Team.new(name: 'test team') }

  subject { ApplicationPolicy.new(user, nil).policy_for(team) }

  describe 'index?' do
    it 'is true for any user' do
      expect(subject.index?).to eq(true)
    end
    context 'when user is nil' do
      let(:user) {}
      it 'is false' do
        expect(subject.index?).to eq(false)
      end
    end
  end

  describe 'new?' do
    it 'is true for any user' do
      expect(subject.index?).to eq(true)
    end
    context 'when user is nil' do
      let(:user) {}
      it 'is false' do
        expect(subject.index?).to eq(false)
      end
    end
  end

  describe 'receive is_editable_by?' do
    before do
      allow(subject).to receive(:is_editable_by?).with(user.id).and_return(:result_from_is_editable_by?)
    end

    describe 'show?' do
      it 'is the value of is_editable_by? for the user_id' do
        expect(subject.show?).to eq(:result_from_is_editable_by?)
      end
    end

    describe 'edit?' do
      it 'is the value of is_editable_by? for the user_id' do
        expect(subject.edit?).to eq(:result_from_is_editable_by?)
      end
    end

    describe 'create?' do
      it 'is the value of is_editable_by? for the user_id' do
        expect(subject.create?).to eq(:result_from_is_editable_by?)
      end
    end

    describe 'update?' do
      it 'is the value of is_editable_by? for the user_id' do
        expect(subject.update?).to eq(:result_from_is_editable_by?)
      end
    end

    describe 'destroy?' do
      it 'is the value of is_editable_by? for the user_id' do
        expect(subject.destroy?).to eq(:result_from_is_editable_by?)
      end
    end
  end

  describe 'is_editable_by?' do
    context 'for a team created by the user' do
      before do
        team.created_by_user = user
      end

      it 'is true' do
        expect(subject.send(:is_editable_by?, user.id)).to eq(true)
      end
    end

    context 'for a team not created by the user' do
      let(:other_user) { User.create!(name: 'other user') }
      before do
        team.created_by_user = other_user
        team.save!
      end

      context 'but with the user as a member' do
        before do
          team.members.create!(user: user, created_by_user: other_user)
        end
        it 'is true' do
          expect(subject.send(:is_editable_by?,user.id)).to eq(true)
        end
      end

      context 'and without the user as a member' do
        it 'is false' do
          expect(subject.send(:is_editable_by?,user.id)).to eq(false)
        end
      end
    end
  end
end
