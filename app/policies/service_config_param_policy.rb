class ServiceConfigParamPolicy < ApplicationPolicy
  delegate_to(:service)
end
