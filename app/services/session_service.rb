class SessionService

  def self.process!(userinfo, session)
    auth0_user_session = build_user_session(userinfo)

    if auth0_user_session.new_user?
      create_user!(auth0_user_session)
    end
    # raises SignupNotAllowedError if not valid, else returns
    # the auth0_user_session object
    auth0_user_session.save_to!(session)
  end

  def self.build_user_session(userinfo)
    # do we have this user already in the system?
    asserted_identity = AssertedIdentity.from_auth0_userinfo(userinfo)
    existing_user = UserService.existing_user_with(asserted_identity)

    Auth0UserSession.new(
      new_user: (not existing_user.present?),
      user_id: existing_user.try(:id),
      user_info: userinfo
    )
  end

  private

  def self.create_user!(auth0_user_session)
    new_user = UserService.create!(AssertedIdentity.from_auth0_userinfo(auth0_user_session.user_info))
    auth0_user_session.user_id = new_user.id
    auth0_user_session.new_user = true
  end
end
