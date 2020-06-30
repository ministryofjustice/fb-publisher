class Auth0Controller < ApplicationController
  skip_before_action :verify_authenticity_token, only: :developer_callback

  # TODO: method too long, refactor this functionality out
  def callback
    # This stores all the user information that came from Auth0
    # and the IdP
    userinfo = request.env['omniauth.auth']

    begin
      result = SessionService.process!(userinfo, session)

      if result.new_user?
        redirect_to welcome_path
      else
        # Redirect to the URL you want after successful auth
        redirect_to services_path,
                    flash: {
                      success: I18n.t(:welcome_html, scope: [:auth, :existing_user])
                    }
      end
    rescue SignupNotAllowedError
      # no new user or existing user, so they weren't allowed to sign up
      redirect_to signup_not_allowed_path
    end
  end

  def developer_callback
    fail unless Rails.env.development?

    callback
  end

  def failure
    # show a failure page or redirect to an error page
    @error_type = request.params['error_type']
    @error_msg = request.params['message']
    flash[:error] = @error_msg
    redirect_to signup_error_path(error_type: @error_type)
  end
end
