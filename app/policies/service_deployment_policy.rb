class ServiceDeploymentPolicy < ApplicationPolicy
  def index?
    policy_for(record.service).show?
  end

  def new?
    policy_for(record.service).update?
  end

  def show?
    policy_for(record.service).show?
  end

  def edit?
    policy_for(record.service).update?
  end

  def update?
    policy_for(record.service).update?
  end

  def create?
    policy_for(record.service).update?
  end

  def destroy?
    policy_for(record.service).update?
  end
end
