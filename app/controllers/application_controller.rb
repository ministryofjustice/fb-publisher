class ApplicationController < ActionController::Base
  include Auth0Helper
  include Pundit
  protect_from_forgery

  before_action :identify_user
  around_action :set_time_zone, if: :current_user

  rescue_from Pundit::Error, with: :pundit_errors

  private

  def set_time_zone(&block)
    Time.use_zone(current_user.timezone, &block)
  end

  def pundit_errors(e)
    scope = %i[errors pundit]
    flash[:error] = I18n.t(e.class.name.underscore.gsub('/', '_'),
                           scope: scope, message: e.class.name.underscore,
                           default: I18n.t(:default, scope: scope))

    redirect_to(request.referrer || root_path)
  end
end
