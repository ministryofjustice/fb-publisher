class TeamPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def new?
    user.present?
  end

  def show?
    is_editable_by?(user.id)
  end

  def edit?
    is_editable_by?(user.id)
  end

  def update?
    is_editable_by?(user.id)
  end

  def create?
    is_editable_by?(user.id)
  end

  def destroy?
    is_editable_by?(user.id)
  end

  private

  def is_editable_by?(user_id)
    user.id == record.created_by_user_id || \
      record.members.where(user_id: user_id).exists?
  end
end
