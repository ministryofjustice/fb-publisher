class AddPrivilegedToServiceConfigParams < ActiveRecord::Migration[5.2]
  def change
    add_column :service_config_params, :privileged, :boolean, null: false, default: false
  end
end
