module Auth0Helper
  # What's the current_user?
  # @return [Hash]
  def current_user
    @current_user
  end

  # @return the path to the login page
  def login_path
    root_path
  end
  
  private

  # Is the user signed in?
  # @return [Boolean]
  def user_signed_in?
    session.try(:[],:user_id).present?
  end

  def identify_user(user_id = session[:user_id])
    if user_signed_in?
      @current_user ||= User.where(id: user_id).first
    end
  end

  # Set the @current_user or redirect to public page
  def require_user!
    # Redirect to page that has the login here
    if user_signed_in?
      identify_user
    else
      redirect_to login_path
    end
  end

end
