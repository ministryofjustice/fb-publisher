class Team < ActiveRecord::Base
  include Concerns::HasSlug

  belongs_to :created_by_user, class_name: "User", foreign_key: :created_by_user_id

  validates :name, length: {minimum: 3, maximum: 128}, uniqueness: true

  # Naive first impl - just teams created by the given user
  # TODO: revisit once we have concept of team membership
  def self.visible_to(user_or_user_id)
    user_id = user_or_user_id.is_a?(User) ? user_or_user_id.id : user_or_user_id
    where(created_by_user_id: user_id)
  end

  private

end
