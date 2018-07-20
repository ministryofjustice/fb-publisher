class AddTeamMemberCreatedByUser < ActiveRecord::Migration[5.2]
  def change
    add_column :team_members, :created_by_user_id, :uuid, null: true

    add_foreign_key :team_members, :users, type: :uuid, column: :created_by_user_id
  end
end
