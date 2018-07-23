class Permission < ActiveRecord::Base
  include Concerns::CreatedByUser

  belongs_to :team
  belongs_to :service

  def self.for_user_id(user_id)
    includes(:team).joins(team: :members)
                  .where(team_members: {user_id: user_id})
  end
end
