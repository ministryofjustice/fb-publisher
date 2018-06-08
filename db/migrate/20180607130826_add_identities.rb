class AddIdentities < ActiveRecord::Migration[5.2]
  def change
    create_table :identities, id: :uuid do |t|
      t.string          :provider
      t.string          :uid
      t.string          :name, null: true
      t.string          :email, null: true, unique: true
    end
    add_reference :identities, :user, type: :uuid, foreign_key: true

    add_index :identities, [:provider, :uid]
    add_index :identities, [:email]
  end
end
