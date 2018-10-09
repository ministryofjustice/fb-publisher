
class Services::PermissionsController < ApplicationController
  before_action :require_user!

  include Concerns::NestedResourceController
  nest_under :service, attr_name: :slug, param_name: :service_slug

  before_action :load_and_authorize_resource!, only: [:edit, :update, :destroy]

  def index
    params[:order] ||= 'teams.name'
    # NOTE: no visible_to scope - we're assuming that all permissions of a service
    # can see each other.
    @permissions = @service.permissions
                      .includes(:team)
                      .order(params[:order] || 'users.name')
    @permission = Permission.new( service: @service )
    @possible_teams = Team.visible_to(current_user) - @service.teams
  end

  # called (remotely) from the "add" button in index
  def create
    @permission = Permission.new(
      permissions_params.merge(
        service: @service,
        created_by_user: @current_user
      )
    )
    authorize(@permission)

    if @permission.save
      redirect_to action: :index, service_id: @service
    else
      render :new
    end
  end

  def edit
    if request.xhr?
      render partial: 'form', locals: {permission: @permission}
    else
      # default
    end
  end

  def update
    if @permission.update(
      permissions_params.merge(created_by_user: current_user)
    )
      flash[:notice] = t(
        :success,
        scope: [:services, :permissions, :update],
        name: @permission.name
      )
      redirect_to action: :index,
                  env: @permission.environment_slug
    else
      render :edit
    end
  end


  def destroy
    @permission.destroy!
    redirect_to action: :index, service_id: @service
  end

  private

  def load_and_authorize_resource!
    @permission = @service.permissions.find(params[:id])
    authorize(@permission)
  end

  def permissions_params( opts = params )
    opts.fetch(:permission).permit(
      :team_id,
      :service_id
    )
  end
end
