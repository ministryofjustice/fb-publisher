class AddSuperUserToTeam < ActiveRecord::Migration[5.2]
  def change
    add_column :teams, :super_admin, :boolean, default: false
  end
end
