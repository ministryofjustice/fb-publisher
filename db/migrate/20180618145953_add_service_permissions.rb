class AddServicePermissions < ActiveRecord::Migration[5.2]
  def change
    create_table :service_permissions, id: :uuid do |t|
      t.string        :role
      t.timestamps
      t.uuid          :created_by_user_id
    end

    add_reference :service_permissions, :services, type: :uuid, foreign_key: true
    add_reference :service_permissions, :users, type: :uuid, foreign_key: true
    add_foreign_key :service_permissions, :users, column: :created_by_user_id
  end
end
