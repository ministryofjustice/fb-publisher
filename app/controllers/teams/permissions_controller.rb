
class Teams::PermissionsController < ApplicationController
  before_action :require_user!

  include Concerns::NestedResourceController
  nest_under :team, attr_name: :slug, param_name: :team_slug

  before_action :load_and_authorize_resource!, only: [:edit, :update, :destroy]

  def index
    params[:order] ||= 'services.name'
    # NOTE: no visible_to scope - we're assuming that all permissions of a team
    # can see each other.
    @permissions = @team.permissions
                      .includes(:service)
                      .order(params[:order] || 'users.name')
    @permission = Permission.new( team: @team )
    @possible_services = Service.visible_to(current_user) - @team.services
  end

  # called (remotely) from the "add" button in index
  def create
    @permission = Permission.new(
      permissions_params.merge(
        team: @team,
        created_by_user: @current_user
      )
    )
    authorize(@permission)

    if @permission.save
      redirect_to action: :index, team_id: @team
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
        scope: [:teams, :permissions, :update],
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
    redirect_to action: :index, team_id: @team
  end

  private

  def load_and_authorize_resource!
    @permission = @team.permissions.find(params[:id])
    authorize(@permission)
  end

  def permissions_params( opts = params )
    opts.fetch(:permission).permit(
      :service_id,
      :team_id
    )
  end
end
