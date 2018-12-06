class AddSuperAdminTeam < ActiveRecord::DataMigration
  def up
    user = User.find_by_name('Andrien Ricketts')
    Team.create!(name: 'Super Admin', created_by_user_id: user.id, super_admin: true)
  end
end