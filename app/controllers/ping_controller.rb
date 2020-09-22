class PingController < ApplicationController
  def show
    render json: { status: :ok }
  end
end
