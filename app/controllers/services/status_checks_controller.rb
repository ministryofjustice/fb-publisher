class Services::StatusChecksController < ApplicationController
  before_action :require_user!
  include Concerns::NestedResourceController
  nest_under :service, attr_name: :slug, param_name: :service_id

  # called from the "Check now" button in service show
  def create
    @check = StatusService.check(
      service: @service,
      environment_slug: params[:environment_slug],
      timeout: 5
    )

    respond_to do |format|
      format.html do
        redirect_to service_path(@service)
      end
    end
  end
end
