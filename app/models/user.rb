class User < ActiveRecord::Base
  has_many :identities, dependent: :destroy
  has_many :services_as_creator, foreign_key: :created_by_user_id, class_name: "Service"

  has_many :memberships, class_name: "TeamMember", dependent: :destroy
  has_many :teams_as_creator, foreign_key: :created_by_user_id, class_name: "Team"
  has_many :teams_as_member, through: :memberships, source: :team

  # MVP version: every user can see every other user
  def self.visible_to(user_or_user_id)
    user_id = user_or_user_id.is_a?(User) ? user_or_user_id.id : user_or_user_id
    where(true)
  end

end
