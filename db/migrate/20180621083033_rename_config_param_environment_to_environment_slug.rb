class RenameConfigParamEnvironmentToEnvironmentSlug < ActiveRecord::Migration[5.2]
  def change
    rename_column :service_config_params, :environment, :environment_slug
  end
end
