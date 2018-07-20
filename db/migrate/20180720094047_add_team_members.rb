class AddTeamMembers < ActiveRecord::Migration[5.2]
  def change
    create_table :team_members, id: :uuid do |t|
      t.timestamps
    end

    add_reference :team_members, :user, type: :uuid, foreign_key: true
    add_reference :team_members, :team, type: :uuid, foreign_key: true
  end
end
