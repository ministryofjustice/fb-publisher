class ServiceDeploymentPolicy < ApplicationPolicy
  delegate_to(:service)
end
