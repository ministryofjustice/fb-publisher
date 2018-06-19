class AddServiceConfigParams < ActiveRecord::Migration[5.2]
  def change
    create_table :service_config_params, id: :uuid do |t|
      t.string              :environment
      t.string              :name
      t.string              :value
      t.timestamps
      t.uuid                :last_update_by_user_id
    end

    add_reference :service_config_params, :service, type: :uuid, foreign_key: true
  end
end
