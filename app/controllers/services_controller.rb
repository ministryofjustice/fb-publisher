class ServicesController < ApplicationController
  before_action :require_user!
  before_action :load_and_authorize_resource!, only: [:edit, :update, :destroy, :show]

  include Pagy::Backend

  def index
    params[:per_page] ||= 10
    params[:page] ||= 1

    services = policy_scope(Service).contains(filter_params[:query]).sort_by &:name
    services = policy_scope(Service).sort_by &:name if services.empty?

    @pagy, @services = pagy_array(services, items: params[:per_page])
  end

  def new
    @service = Service.new(created_by_user: current_user)
    authorize(@service)
  end

  def create
    @service = Service.new(service_params.merge(created_by_user: current_user))
    authorize(@service)
    if @service.save
      redirect_to service_path(@service), notice: t(:success, scope: [:services, :create])
    else
      render :new
    end
  end

  def edit_confirm
    @service = Service.find_by_slug(service_params[:slug])
  end

  def destroy
    # add job to remove the deployments for each environment(if they exist) of a service
    # then delete the service
    ServiceEnvironment.all_slugs.each do |env|
      deployment = DeploymentService.last_status(service: @service, environment_slug: env)
      DeployServiceJob.perform_later(service_deployment_id: deployment.id) unless deployment.nil?
    end
    @service.destroy!
    redirect_to services_path, notice: t(:success, scope: [:services, :destroy], service: @service.name)
  end

  def update
    if params[:commit] == t('services.edit_confirm.confirm') || @service.slug == service_params[:slug]
      redirect(@service, service_params)
    elsif @service.slug != service_params[:slug]
      render :edit_confirm
    end
  end

  def show
    @status_by_environment = ServiceDeploymentStatus.all(@service)
  end

  private

  def load_and_authorize_resource!
    @service = Service.find_by_slug(params[:slug])
    authorize(@service)
  end

  def service_params
    params[:service].permit([:git_repo_url, :name, :slug])
  end

  def filter_params
    params.permit([:query])
  end

  def redirect(service, params)
    if @service.update(params)
      redirect_to service_path(service), notice: t(:success, scope: [:services, :update], service: @service.name)
    else
      render :edit
    end
  end
end
