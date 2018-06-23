class UserService
  def self.existing_user_with(identity)
    identity = Identity.where(
      uid: identity.uid,
      provider: identity.provider
    ).first.try(:user)
  end

  def self.create!(identity)
    new_user = User.create!(
      name: identity.name,
      email: identity.email
    )
    new_user.identities << Identity.new(
      name: identity.name,
      email: identity.email,
      provider: identity.provider,
      uid: identity.uid
    )
    new_user
  end
end
