module ApplicationHelper
  def current_action?(controller:, action:)
    controller.to_s == params[:controller] \
      && action.to_s == params[:action]
  end
end
