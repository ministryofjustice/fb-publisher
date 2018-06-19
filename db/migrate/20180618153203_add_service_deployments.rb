class AddServiceDeployments < ActiveRecord::Migration[5.2]
  def change
    create_table :service_deployments, id: :uuid do |t|
      t.string        :commit_sha
      t.string        :environment
      t.timestamps
      t.uuid          :created_by_user_id
    end

    add_reference :service_deployments, :service
    add_foreign_key :service_deployments, :users, column: :created_by_user_id
  end
end
