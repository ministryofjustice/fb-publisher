class Team < ActiveRecord::Base
  include Concerns::HasSlug
  include Concerns::CreatedByUser

  has_many    :members, class_name: 'TeamMember', dependent: :destroy
  has_many    :users_as_member, through: :members, source: :user
  has_many    :permissions
  has_many    :services, through: :permissions

  validates :name, length: {minimum: 3, maximum: 128}, uniqueness: true

  # A user can see teams created by them, or
  # for which they are a member
  def self.visible_to(user_or_user_id)
    user_id = user_or_user_id.is_a?(User) ? user_or_user_id.id : user_or_user_id

    # Arel doesn't really support doing all of this in one query
    # so we'll just get the distinct ids of each of the two cases
    # and do an IN() query for them.
    # Benefits: each separate query can be cached
    # Drawbacks: not going to scale beyond a few hundred teams-per-user
    # (that limitation is OK for now, and TBH I can't see many users
    # creating more than that)
    ids = with_user_as_member(user_id).pluck(:id) + \
          created_by_user(user_id).pluck(:id)
    where("id IN(?)", ids.uniq)
  end

  def self.with_user_as_member(user_id)
    joins(:members).where(team_members: {user_id: user_id})
  end

  private

end
