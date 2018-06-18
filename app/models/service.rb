class Service < ActiveRecord::Base
  belongs_to :user, foreign_key: :created_by_user_id

  # Naive first impl - just services created by the given user
  # TODO: revisit once we have concept of teams
  def self.visible_to(user_or_user_id)
    user_id = user_or_user_id.is_a?(User) ? user_or_user_id.id : user_or_user_id
    where(created_by_user_id: user_id)
  end
end
