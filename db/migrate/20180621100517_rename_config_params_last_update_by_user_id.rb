class RenameConfigParamsLastUpdateByUserId < ActiveRecord::Migration[5.2]
  def change
    rename_column :service_config_params, :last_update_by_user_id, :last_updated_by_user_id
  end
end
