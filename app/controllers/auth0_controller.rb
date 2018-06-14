class Auth0Controller < ApplicationController
  def callback
    # This stores all the user information that came from Auth0
    # and the IdP
    userinfo = request.env['omniauth.auth']

    # do we have this user already in the system?
    asserted_identity = AssertedIdentity.from_auth0_userinfo(userinfo)
    existing_user = UserService.existing_user_with(asserted_identity)

    auth0_user_session = Auth0UserSession.new(
      user_id: existing_user.try(:id),
      user_info: userinfo
    )

    # if a user already exists with the given identity
    if existing_user.present?
      # store them
      auth0_user_session.save_to(session)
      # Redirect to the URL you want after successful auth
      redirect_to dashboard_path, 
                  notice: I18n.t(:welcome_html,
                                  scope: [:auth, :existing_user],  
                                  user_name: existing_user.name)
    else
      # is the user OK to sign up? (ie. has a justice.gov.uk email)
      if auth0_user_session.valid?
        new_user = create_user!(auth0_user_session, asserted_identity)
        auth0_user_session.user_id = new_user.id
        auth0_user_session.save_to(session)
        redirect_to welcome_path
      else
        render :signup_not_allowed, locals: { user_session: auth0_user_session }
      end
    end
  end

  def failure
    # show a failure page or redirect to an error page
    @error_type = request.params['error_type']
    @error_msg = request.params['message']
  end

  def signup_not_allowed

  end

  private

  def create_user!(user_session, asserted_identity)
    new_user = User.create(
      name: user_session.name,
      email: user_session.email
    )
    new_user.identities << asserted_identity.to_identity
    new_user
  end


end
