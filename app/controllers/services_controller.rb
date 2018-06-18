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

  def show
    @service = Service.find(id: params[:id])
    authorize(@service)
  end

  private

  def service_params
    params[:service].permit([:name, :slug])
  end
end
