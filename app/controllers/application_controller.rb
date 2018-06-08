class ApplicationController < ActionController::Base
  include Auth0Helper
  
  before_action :identify_user
end
