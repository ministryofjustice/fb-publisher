class HomeController < ApplicationController
  def show
    redirect_to(dashboard_path) if @current_user
  end
end
