class AddSuperAdminPermissionsToPreviouslyGeneratedForms < ActiveRecord::DataMigration
  def up
    admin = Team.find_by(super_admin: true)
    return if admin.nil?

    services = Service.all
    services.each do |service|
      permission = Permission.find_by(service_id: service.id, team_id: admin.id)
      Permission.create(service_id: service.id, team_id: admin.id, created_by_user_id: service.created_by_user_id) if permission.nil?
    end
  end
end
