class PermissionPolicy < ApplicationPolicy
  def index?
    policy_for(record.team).show?
  end

  def new?
    policy_for(record.team).update?
  end

  def show?
    policy_for(record.team).show?
  end

  def edit?
    policy_for(record.team).update?
  end

  def update?
    policy_for(record.team).update?
  end

  def create?
    policy_for(record.team).update?
  end

  def destroy?
    policy_for(record.team).update?
  end
end
