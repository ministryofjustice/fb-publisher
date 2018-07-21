class AddPermissions < ActiveRecord::Migration[5.2]
  def change
    create_table :permissions, id: :uuid do |t|
      t.timestamps
    end

    add_reference :permissions, :service, type: :uuid, foreign_key: true
    add_reference :permissions, :team, type: :uuid, foreign_key: true
  end
end
