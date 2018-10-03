class PopulateEmptyServiceTokens < ActiveRecord::Migration[5.2]
  def change
    Service.where(token: nil).each{|s| s.save!}
  end
end
