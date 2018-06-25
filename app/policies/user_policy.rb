class UserPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def new?
    user.present?
  end

  def show?
    user.present?
  end

  def edit?
    user.id == record.id
  end

  def update?
    user.id == record.id
  end

  def create?
    user.id == record.created_by_user_id
  end

  def destroy?
    user.id == record.id
  end
end
