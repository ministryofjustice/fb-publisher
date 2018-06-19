class ServicesController < ApplicationController
  before_action :require_user!

  def index
    authorize(Service)
    @services = Service.visible_to(current_user)
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

  def destroy
    @service = Service.find_by_slug(params[:id])
    authorize(@service)
    @service.destroy!
    redirect_to index_path, notice: t(:success, scope: [:services, :destroy], service: @service.name)
  end

  def show
    @service = Service.find_by_slug(params[:id])
    authorize(@service)
    @status_by_environment = StatusService.service_status(@service)
  end

  private

  def service_params
    params[:service].permit([:name, :slug])
  end
end
