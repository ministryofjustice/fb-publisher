class TeamsController < ApplicationController
  before_action :require_user!
  before_action :load_and_authorize_resource!, only: [:edit, :update, :destroy, :show]

  include Pagy::Backend

  def index
    params[:per_page] ||= 10
    params[:page] ||= 1

    teams = Team.visible_to(@current_user)
    @pagy, @teams = pagy_array(teams, items: params[:per_page])
  end

  def new
    @team = Team.new(created_by_user: current_user)
    authorize(@team)
  end

  def create
    @team = Team.new(team_params.merge(created_by_user: current_user))
    authorize(@team)
    if @team.save
      redirect_to team_path(@team), flash: { success: t(:success, scope: [:teams, :create]) }
    else
      render :new
    end
  end

  def edit; end

  def destroy
    @team.destroy!
    redirect_to teams_path, flash: { success: t(:success, scope: [:teams, :destroy], team: @team.name) }
  end

  def update
    if @team.update(team_params)
      redirect_to team_path(@team), flash: { success: t(:success, scope: [:teams, :update], team: @team.name) }
    else
      render :edit
    end
  end

  def show; end

  private

  def load_and_authorize_resource!
    @team = Team.find_by_slug(params[:slug])
    authorize(@team)
  end

  def team_params
    params[:team].permit([:name, :slug])
  end
end

