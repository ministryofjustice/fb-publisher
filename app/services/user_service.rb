class UserService
  def self.existing_user_with(identity)
    Identity.where(
      uid: identity.uid,
      provider: identity.provider
    ).first.try(:user) || \
      User.where(email: identity.email).first
  end

  def find_by_email(email)

  end

  def self.create!(identity)
    new_user = User.create!(
      name: identity.name,
      email: identity.email
    )
    add_identity!(new_user, identity)
    new_user
  end

  def self.add_identity!(user, identity)
    user.identities << Identity.new(
      name: identity.name,
      email: identity.email,
      provider: identity.provider,
      uid: identity.uid
    )
  end
end
