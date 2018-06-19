class AddServiceStatusChecks < ActiveRecord::Migration[5.2]
  def change
    create_table :service_status_checks, id: :uuid do |t|
      t.string        :environment_slug
      t.integer       :status, nil: true
      t.float         :time_taken
      t.string        :url
      t.datetime      :timestamp
      t.timestamps
    end

    add_reference :service_status_checks, :service, type: :uuid, foreign_key: true
  end
end
