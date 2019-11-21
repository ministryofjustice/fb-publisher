class DropServiceStatusChecks < ActiveRecord::Migration[6.0]
  def change
    drop_table :service_status_checks
  end
end
