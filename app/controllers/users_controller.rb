class UsersController < ApplicationController
  before_action :require_user!

  def edit
    @timezones = ActiveSupport::TimeZone.all.collect(&:name).sort.map! { |zone| [zone, zone] }
  end

  def update
    if @current_user.update_attributes(user_params)
      @current_user.save!
      flash[:success] = I18n.t('users.update.success')
    else
      flash[:error] = I18n.t('users.update.error')
    end
    redirect_to action: :edit
  end

  private

  def user_params
    params.require(:user).permit(:id, :name, :timezone, :updated_at)
  end
end
