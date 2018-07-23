class TeamMemberPolicy < ApplicationPolicy
  delegate_to(:team)
end
