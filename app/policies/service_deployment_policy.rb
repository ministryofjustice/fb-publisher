class ServiceDeploymentPolicy < ApplicationPolicy
  delegate_to(:service)

  def log?
    show?
  end
end
