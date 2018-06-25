
class Services::DeploymentsController < ApplicationController
  before_action :require_user!

  include Concerns::NestedResourceController
  nest_under :service, attr_name: :slug, param_name: :service_slug

  before_action :load_and_authorize_resource!, only: [:edit, :update, :destroy]

  def status
    @environments = ServiceEnvironment.all
    @deployments_by_environment = DeploymentService.service_status(@service)
  end

  # called (remotely) from the "add" button in index
  def create
    @deployment = ServiceDeployment.new(
      deployments_params.merge(
        service: @service,
        created_by_user: @current_user
      )
    )
    authorize(@deployment)

    if @deployment.save
      redirect_to action: :index, service_id: @service, env: @deployment.environment_slug
    else
      render :new
    end
  end

  def edit
    if request.xhr?
      render partial: 'form', locals: {deployment: @deployment}
    else
      # default
    end
  end

  def update
    if @deployment.update(
      deployments_params.merge(created_by_user: current_user)
    )
      flash[:notice] = t(
        :success,
        scope: [:services, :deployments, :update],
        name: @deployment.name,
        environment: ServiceEnvironment.name_of(@deployment.environment_slug)
      )
      redirect_to action: :index,
                  env: @deployment.environment_slug
    else
      render :edit
    end
  end


  def destroy
    @deployment.destroy!
    redirect_to action: :index, service_id: @service, env: @deployment.environment_slug
  end

  private

  def load_and_authorize_resource!
    @deployment = @service.service_deployments.find(params[:id])
    authorize(@deployment)
  end

  def deployments_params( opts = params )
    opts.fetch(:service_deployment).permit(
      :environment_slug,
      :name,
      :service_id,
      :value
    )
  end
end
