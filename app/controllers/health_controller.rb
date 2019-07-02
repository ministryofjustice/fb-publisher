class HealthController < ApplicationController
  def show
    render plain: 'healthy'
  end
end
