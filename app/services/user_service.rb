class UserService
  def self.existing_user_with(identity)
    identity = Identity.where(
      uid: identity.uid,
      provider: identity.provider
    ).first.try(:user)
  end

  def self.add_user_identity(user, identity)
    User.identities << identity
  end
end
