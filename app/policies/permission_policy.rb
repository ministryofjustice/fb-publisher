class PermissionPolicy < ApplicationPolicy
  delegate_to(:team)
end
