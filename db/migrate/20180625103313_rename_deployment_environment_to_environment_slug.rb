class RenameDeploymentEnvironmentToEnvironmentSlug < ActiveRecord::Migration[5.2]
  def change
    rename_column :service_deployments, :environment, :environment_slug
  end
end
