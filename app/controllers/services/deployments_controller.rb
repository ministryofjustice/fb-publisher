
class Services::DeploymentsController < ApplicationController
  before_action :require_user!

  include Concerns::NestedResourceController
  nest_under :service, attr_name: :slug, param_name: :service_slug

  before_action :load_and_authorize_resource!, only: [:edit, :update, :destroy]

  def index
    params[:per_page] ||= 10
    params[:page] ||= 1
    params[:order] ||= 'created_at'
    params[:dir] ||= 'desc'

    @environments = ServiceEnvironment.all
    @deployments = DeploymentService.list(
      service: @service,
      environment_slug: params[:env],
      page: params[:page],
      per_page: params[:per_page],
      order: params[:order],
      dir: params[:dir]
    )
    @deployment = ServiceDeployment.new(service: @service, environment_slug: params[:env])
  end

  def status
    @environments = ServiceEnvironment.all
    @deployments_by_environment = DeploymentService.service_status(@service)
  end

  # called (remotely) from the "add" button in index
  def create
    @deployment = ServiceDeployment.new(
      deployments_params.merge(
        service: @service,
        created_by_user: @current_user,
        status: ServiceDeployment::STATUS[:queued]
      )
    )
    authorize(@deployment)

    if @deployment.save
      DeployServiceJob.perform_later(service_deployment_id: @deployment.id)
      redirect_to action: :index, service_slug: @service, env: @deployment.environment_slug
    else
      @environment = ServiceEnvironment.find(@deployment.environment_slug)
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

  def new
    @deployment = ServiceDeployment.new(service: @service, environment_slug: params[:env])
    @environment = ServiceEnvironment.find(params[:env])
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
      :value,
      :json_sub_dir
    )
  end
end
