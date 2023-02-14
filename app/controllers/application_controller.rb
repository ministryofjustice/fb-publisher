class ApplicationController < ActionController::Base
  include Auth0Helper
  include Pundit::Authorization
  protect_from_forgery

  before_action :identify_user
  around_action :set_time_zone, if: :current_user
  before_action :identify_public_user, if: :current_user

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

  def identify_public_user
    if public_user?
      session.clear
      flash[:alert] = I18n.t('errors.access_denied').html_safe
      redirect_to root_path
    end
  end

  def public_user?
    Rails.application.config.moj_forms_team.exclude?(current_user.email)
  end
end
