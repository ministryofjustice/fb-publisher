class UndeployServiceJob < ApplicationJob
  queue_as :default

  def perform(env:, service_slug:)
    @slug = service_slug
    @env = env

    log_for_user(:stop_service)
    DeploymentService.stop_service_by_slug(environment_slug: env.to_sym, slug: service_slug)
    log_for_user(:all_done)
  end

  def on_retryable_exception(error)
    logger.warn "RETRYABLE EXCEPTION! un-deployment failure #{@slug}, #{@env}"
    super
  end

  def on_non_retryable_exception(error)
    log_for_user(:failed)
    super
  end

  def self.log_tag
    ['environment slug', @env].join(':')
  end

  def log_for_user(message_key, args={})
    i18n_args = {
      scope: [:undeploy_service_job],
      service_slug: @slug,
      job_id: job_id
    }.merge(args)

    JobLogService.log(
      message: I18n.t(
        message_key,
        i18n_args
      ),
      job: self,
      tag: self.class.log_tag
    )
  end
end
