class UserSessionsController < ApplicationController
  before_action :require_user!

  def destroy
    session.clear
    flash[:success] = I18n.t(:success, scope: [:user_sessions, :destroy])
    redirect_to root_path 
  end
end
