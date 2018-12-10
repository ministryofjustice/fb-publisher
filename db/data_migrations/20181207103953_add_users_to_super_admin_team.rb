class AddUsersToSuperAdminTeam < ActiveRecord::DataMigration
  def up
    team = Team.find_by(name: 'Super Admin')

    return if team.nil?

    users = []
    users << User.find_by(email: 'andrien.ricketts@digital.justice.gov.uk')
    users << User.find_by(email: 'alex.robinson@digital.justice.gov.uk')
    users << User.find_by(email: 'sophie.osman@digital.justice.gov.uk')
    users << User.find_by(email: 'anna.brennan@digital.justice.gov.uk')
    users << User.find_by(email: 'daphne.haitas@digital.justice.gov.uk')
    users << User.find_by(email: 'elliot.bouher@digital.justice.gov.uk')

    users.each do |user|
      next if user.nil?

      next unless TeamMember.find_by(user_id: user.id, team_id: team.id).nil?

      TeamMember.create(user_id: user.id, team_id: team.id, created_by_user_id: team.created_by_user_id)
    end
  end
end
