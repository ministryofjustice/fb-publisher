class ServicesController < ApplicationController
  before_action :require_user!
  before_action :load_and_authorize_resource!, only: [:edit, :update, :destroy, :show]

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

  def edit
  end

  def destroy
    @service.destroy!
    redirect_to index_path, notice: t(:success, scope: [:services, :destroy], service: @service.name)
  end

  def update
    if @service.save
      redirect_to service_path(@service), notice: t(:success, scope: [:services, :create])
    else
      render :edit
    end
  end

  def show
    @status_by_environment = StatusService.service_status(@service)
  end

  private

  def load_and_authorize_resource!
    @service = Service.find_by_slug(params[:slug])
    authorize(@service)
  end

  def service_params
    params[:service].permit([:name, :slug])
  end
end
