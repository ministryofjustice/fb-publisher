class Services::ConfigParamsController < ApplicationController
  before_action :require_user!
  include Concerns::NestedResourceController
  nest_under :service, attr_name: :slug, param_name: :service_id

  def index
    params[:env] ||= 'dev'
    params[:order] ||= 'name'
    @config_params = @service.service_config_params
                            .visible_to(@current_user)
                            .where(environment_slug: params[:env])
                            .order(params[:order] || :name)
    @environments = ServiceEnvironment.all
  end

  # called (remotely) from the "add" button in index
  def create
    @config_param = ServiceConfigParam.new(
      config_params_params.merge(
        service: @service,
        created_by_user: @current_user
      )
    )
    authorize(@config_param)

    if @config_param.save
      redirect_to :index, service_id: @service
    else
      flash.now[:error] = t('.error', scope: [:config_params, :create])
      render :new
    end
  end
end
