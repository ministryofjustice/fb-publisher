class HomeController < ApplicationController
  def show
    redirect_to(services_path) if @current_user
  end
end
