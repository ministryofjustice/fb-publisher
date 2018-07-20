
class Teams::MembersController < ApplicationController
  before_action :require_user!

  include Concerns::NestedResourceController
  nest_under :team, attr_name: :slug, param_name: :team_slug

  before_action :load_and_authorize_resource!, only: [:edit, :update, :destroy]

  def index
    params[:order] ||= 'users.name'
    # NOTE: no visible_to scope - we're assuming that all members of a team
    # can see each other.
    @members = @team.members
                      .includes(:user)
                      .order(params[:order] || 'users.name')
    @member = TeamMember.new( team: @team )
    @possible_members = User.visible_to(current_user) - @team.users_as_member
  end

  # called (remotely) from the "add" button in index
  def create
    @member = TeamMember.new(
      members_params.merge(
        team: @team,
        created_by_user: @current_user
      )
    )
    authorize(@member)

    if @member.save
      redirect_to action: :index, team_id: @team
    else
      render :new
    end
  end

  def edit
    if request.xhr?
      render partial: 'form', locals: {member: @member}
    else
      # default
    end
  end

  def update
    if @member.update(
      members_params.merge(created_by_user: current_user)
    )
      flash[:notice] = t(
        :success,
        scope: [:teams, :members, :update],
        name: @member.name
      )
      redirect_to action: :index,
                  env: @member.environment_slug
    else
      render :edit
    end
  end


  def destroy
    @member.destroy!
    redirect_to action: :index, team_id: @team
  end

  private

  def load_and_authorize_resource!
    @member = @team.members.find(params[:id])
    authorize(@member)
  end

  def members_params( opts = params )
    opts.fetch(:team_member).permit(
      :user_id,
      :team_id
    )
  end
end
