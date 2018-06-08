class UserSessionsController < ApplicationController
  before_action :require_user!

  def destroy
    session.clear
    redirect_to root_path
  end
end
