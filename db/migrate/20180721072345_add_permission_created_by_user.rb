class AddPermissionCreatedByUser < ActiveRecord::Migration[5.2]
  def change
    add_column :permissions, :created_by_user_id, :uuid, null: true

    add_foreign_key :permissions, :users, type: :uuid, column: :created_by_user_id
  end
end
