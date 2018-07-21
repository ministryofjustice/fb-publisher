class AddTeams < ActiveRecord::Migration[5.2]
  def change
    create_table :teams, id: :uuid do |t|
      t.string        :name, unique: true
      t.string        :slug, unique: true
      t.uuid          :created_by_user_id
      t.timestamps
    end
    add_foreign_key :teams, :users, type: :uuid, foreign_key: true, column: :created_by_user_id
  end
end
