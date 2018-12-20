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

  describe 'show?' do
    before do
      allow(subject).to receive(:is_editable_by?).with(user.id).and_return('is editable by result')
    end
    it 'is the value of is_editable_by? for the user_id' do
      expect(subject.edit?).to eq(subject.send(:is_editable_by?, user.id))
    end
  end

  describe 'edit?' do
    before do
      allow(subject).to receive(:is_editable_by?).with(user.id).and_return('is editable by result')
    end
    it 'is the value of is_editable_by? for the user_id' do
      expect(subject.edit?).to eq(subject.send(:is_editable_by?, user.id))
    end
  end

  describe 'create?' do
    before do
      allow(subject).to receive(:is_editable_by?).with(user.id).and_return('is editable by result')
    end
    it 'is the value of is_editable_by? for the user_id' do
      expect(subject.create?).to eq(subject.send(:is_editable_by?,user.id))
    end
  end

  describe 'update?' do
    before do
      allow(subject).to receive(:is_editable_by?).with(user.id).and_return('is editable by result')
    end
    it 'is the value of is_editable_by? for the user_id' do
      expect(subject.update?).to eq(subject.send(:is_editable_by?,user.id))
    end
  end

  describe 'destroy?' do
    before do
      allow(subject).to receive(:is_editable_by?).with(user.id).and_return('is editable by result')
    end
    it 'is the value of is_editable_by? for the user_id' do
      expect(subject.destroy?).to eq(subject.send(:is_editable_by?,user.id))
    end
  end

  describe 'is_editable_by?' do
    context 'for a team created by the user' do
      before do
        team.created_by_user = user
      end

      it 'is true' do
        expect(subject.send(:is_editable_by?,user.id)).to eq(true)
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
