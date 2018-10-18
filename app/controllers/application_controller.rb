class ApplicationController < ActionController::Base
  include Auth0Helper
  include Pundit
  protect_from_forgery

  before_action :identify_user
  around_action :set_time_zone, if: :current_user

  private

  def set_time_zone(&block)
    Time.use_zone(current_user.timezone, &block)
  end
end
