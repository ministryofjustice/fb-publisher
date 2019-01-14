class CreateSuperAdminTeam < ActiveRecord::DataMigration
  def up
    user = User.find_or_create_by(name: 'Andrien Ricketts', email: 'andrien.ricketts@digital.justice.gov.uk')
    return if user.nil?

    Team.create(name: 'Super Admin', created_by_user_id: user.id, super_admin: true)
  end
end
