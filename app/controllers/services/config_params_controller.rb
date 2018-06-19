class Services::ConfigParamsController < ApplicationController
  before_action :require_user!
  include Concerns::NestedResourceController
  nest_under :service, attr_name: :slug, param_name: :service_id

  def index
  end

  private


end
