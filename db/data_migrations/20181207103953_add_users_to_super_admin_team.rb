class AddUsersToSuperAdminTeam < ActiveRecord::DataMigration
  def up
    team = Team.find_by_name('Super Admin')

    return if team.nil?

    users = []
    users << User.find_by_email('andrien.ricketts@digital.justice.gov.uk')
    users << User.find_by_email('alex.robinson@digital.justice.gov.uk')
    users << User.find_by_email('sophie.osman@digital.justice.gov.uk')
    users << User.find_by_email('anna.brennan@digital.justice.gov.uk')
    users << User.find_by_email('daphne.haitas@digital.justice.gov.uk')
    users << User.find_by_email('elliot.bouher@digital.justice.gov.uk')

    users.each do |user|
      next if user.nil?

      next unless TeamMember.find_by_user_id(user.id).nil?

      TeamMember.create(user_id: user.id, team_id: team.id, created_by_user_id: team.created_by_user_id)
    end
  end
end
