class TeamsController < ApplicationController
  before_action :require_user!

  def index
    @teams = Team.visible_to(@current_user)
  end
end