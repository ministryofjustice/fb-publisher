
class Services::ConfigParamsController < ApplicationController
  before_action :require_user!

  include Concerns::NestedResourceController
  nest_under :service, attr_name: :slug, param_name: :service_slug

  before_action :load_and_authorize_resource!, only: [:edit, :update, :destroy]

  def index
    params[:env] ||= 'dev'
    params[:order] ||= 'name'

    @config_params = policy_scope(Service).find_by(id: @service.id)
                                          .service_config_params
                                          .where(environment_slug: params[:env])
                                          .unprivileged
                                          .order(params[:order] || :name)

    @environments = ServiceEnvironment.all
    @config_param = ServiceConfigParam.new( service: @service,
                                            environment_slug: params[:env] )
  end

  # called (remotely) from the "add" button in index
  def create
    @config_param = ServiceConfigParam.new(
      config_params_params.merge(
        service: @service,
        last_updated_by_user: @current_user
      )
    )
    authorize(@config_param)

    if @config_param.save
      flash[:notice] = t(
          :success,
          scope: [:services, :config_params, :create],
          name: @config_param.name,
          environment: ServiceEnvironment.name_of(@config_param.environment_slug)
      )
      redirect_to action: :index, service_id: @service, env: @config_param.environment_slug
    else
      render :new
    end
  end

  def edit
    if request.xhr?
      render partial: 'form', locals: {config_param: @config_param}
    else
      # default
    end
  end

  def update
    if @config_param.update(
      config_params_params.merge(last_updated_by_user: current_user)
    )
      flash[:notice] = t(
        :success,
        scope: [:services, :config_params, :update],
        name: @config_param.name,
        environment: ServiceEnvironment.name_of(@config_param.environment_slug)
      )
      redirect_to action: :index,
                  env: @config_param.environment_slug
    else
      render :edit
    end
  end


  def destroy
    @config_param.destroy!
    redirect_to action: :index, service_id: @service, env: @config_param.environment_slug
  end

  private

  def load_and_authorize_resource!
    @config_param = @service.service_config_params.find(params[:id])
    authorize(@config_param)
  end

  def config_params_params( opts = params )
    opts.fetch(:service_config_param).permit(
      :environment_slug,
      :name,
      :service_id,
      :value
    )
  end
end
