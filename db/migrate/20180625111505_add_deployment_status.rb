class AddDeploymentStatus < ActiveRecord::Migration[5.2]
  def change
    add_column :service_deployments, :status, :string
  end
end
