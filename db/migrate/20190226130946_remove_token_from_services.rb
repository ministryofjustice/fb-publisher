class RemoveTokenFromServices < ActiveRecord::Migration[5.2]
  def change
    remove_column :services, :token, :string
  end
end
