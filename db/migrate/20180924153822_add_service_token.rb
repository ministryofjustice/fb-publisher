class AddServiceToken < ActiveRecord::Migration[5.2]
  def change
    add_column :services, :token, :string, null: true
    add_index :services, [:token], unique: true
  end
end
