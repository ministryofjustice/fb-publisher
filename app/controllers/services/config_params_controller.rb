class ConfigParamsController < ApplicationController
  before_action :require_user!
  extend Concerns::NestedResourceController
  nest_under :service, attr: :slug, param: :id

  def index
  end

  private


end
