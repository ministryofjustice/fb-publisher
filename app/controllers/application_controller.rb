class ApplicationController < ActionController::Base
  include Auth0Helper
  include Pundit
  protect_from_forgery

  before_action :identify_user
end
