class UserSessionsController < ApplicationController
  before_action :require_user!, except: [:signup_not_allowed]

  def destroy
    session.clear
    flash[:success] = I18n.t(:success, scope: [:user_sessions, :destroy])
    redirect_to root_path
  end

  def signup_not_allowed
    @valid_emails = Auth0UserSession::VALID_EMAIL_DOMAINS
  end
end
