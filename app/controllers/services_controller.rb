class ServicesController < ApplicationController
  before_action :require_user!

  def index
    @services = Service.visible_to(current_user)
  end
end
