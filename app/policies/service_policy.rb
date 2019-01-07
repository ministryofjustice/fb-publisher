class ServicePolicy < ApplicationPolicy
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

  class Scope < Scope
    def resolve
      if user.super_admin?
        scope.all
      else
        scope.visible_to(user.id)
      end
    end
  end

  private

  def is_editable_by?(user_id)
    user.id == record.created_by_user_id || \
      Permission.for_user_id(user_id).where(service_id: record.id).exists? || \
      user.super_admin?
  end
end
