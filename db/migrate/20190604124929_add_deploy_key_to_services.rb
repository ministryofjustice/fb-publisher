class AddDeployKeyToServices < ActiveRecord::Migration[5.2]
  def change
    add_column :services, :deploy_key, :text, null: true
  end
end
