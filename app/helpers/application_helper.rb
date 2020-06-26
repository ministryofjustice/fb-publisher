module ApplicationHelper
  def current_action?(controller:, action: nil)
    controller.to_s == params[:controller].to_s \
      && (action.blank? || action.to_s == params[:action].to_s)
  end

  # provide a cancan-like interface for authorizing actions in views
  def can?(action, object)
    policy = ApplicationPolicy.new(current_user, nil).policy_for(object)
    policy.send( (action.to_s + "?").to_sym )
  end

  def environment_name(slug)
    ServiceEnvironment.find(slug).try(:friendly_name)
  end

  # workaround for a Rails routing issue that's "not possible to fix with
  # the current routing DSL" (https://github.com/rails/rails/issues/14451)
  # Use this method in a url: argument of a form_for call (or form_with)
  # e.g.
  # form_with model: @config_param,
  #           local: true,
  #            url: update_or_create(@config_param)
  def update_or_create(model)
    if model.persisted?
      {action: :update}
    else
      {action: :create}
    end
  end
end
