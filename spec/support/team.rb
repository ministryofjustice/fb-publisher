def create_team(name:)
  visit '/teams/new'
  fill_in :team_name, with: name
  click_on 'Create Team'
end

def add_member_to_team(team_slug:, email:)
  visit "/teams/#{team_slug}/members"
  select email, from: :team_member_user_id
  click_on 'Add member'
end

def grant_permission_to_team(team_slug:, service_name:)
  visit "/teams/#{team_slug}/permissions"
  select service_name, from: :permission_service_id
  click_on 'Grant permission'
end
