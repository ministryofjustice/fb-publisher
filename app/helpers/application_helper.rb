module ApplicationHelper
  def current_action?(controller:, action:)
    controller.to_s == params[:controller].to_s \
      && action.to_s == params[:action].to_s
  end
end
