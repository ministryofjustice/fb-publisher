class AddServiceDeploymentJsonSubDir < ActiveRecord::Migration[5.2]
  def change
    add_column :service_deployments, :json_sub_dir, :string, null: true
  end
end
