class AddServices < ActiveRecord::Migration[5.2]
  def change
    create_table :services, primary_key: :uuid do |t|
      t.string        :name, unique: true
      t.string        :slug, unique: true
      t.string        :git_repo_url
      t.uuid          :created_by_user_id
      t.timestamps
    end
    add_foreign_key :services, :users, column: :created_by_user_id
  end
end
