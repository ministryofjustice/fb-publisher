class AddOrCreateSuperUsers < ActiveRecord::DataMigration
  def up
    team = Team.find_by(name: 'Super Admin')
    return if team.nil?

    users = []
    users << User.find_or_create_by(name: 'Andrien Ricketts', email: 'andrien.ricketts@digital.justice.gov.uk')
    users << User.find_or_create_by(name: 'Alex Robinson', email: 'alex.robinson@digital.justice.gov.uk')
    users << User.find_or_create_by(name: 'Sophie Osman', email: 'sophie.osman@digital.justice.gov.uk')
    users << User.find_or_create_by(name: 'Anna Brennan', email: 'anna.brennan@digital.justice.gov.uk')
    users << User.find_or_create_by(name: 'Daphne Haitas', email: 'daphne.haitas@digital.justice.gov.uk')
    users << User.find_or_create_by(name: 'Elliot Bouher', email: 'elliot.bouher@digital.justice.gov.uk')
    users << User.find_or_create_by(name: 'Phillip Cogger', email: 'phillip.cogger@digital.justice.gov.uk')

    users.each do |user|
      next if user.nil?

      next unless TeamMember.find_by(user_id: user.id, team_id: team.id).nil?

      TeamMember.create(user_id: user.id, team_id: team.id, created_by_user_id: team.created_by_user_id)
    end
  end
end