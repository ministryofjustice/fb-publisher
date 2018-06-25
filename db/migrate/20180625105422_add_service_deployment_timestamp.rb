class AddServiceDeploymentTimestamp < ActiveRecord::Migration[5.2]
  def change
    add_column :service_deployments, :completed_at, :datetime, null: true
    add_index :service_deployments,
              [:service_id, :environment_slug, :completed_at],
              name: 'ix_deployments_service_env_completed'
  end

end
