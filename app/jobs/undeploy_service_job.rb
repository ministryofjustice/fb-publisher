class UndeployServiceJob < ApplicationJob
  queue_as :default

  def perform(service_deployment_id:)
    @service_deployment_id = service_deployment_id
    @deployment = ServiceDeployment.find(service_deployment_id)

    log_for_user(:stop_service)
    DeploymentService.stop_service(
      environment_slug: @deployment.environment_slug,
      service: @deployment.service
    )

    log_for_user(:removed)
    @deployment.remove!

    log_for_user(:all_done)
  end

  def on_retryable_exception(error)
    logger.warn "RETRYABLE EXCEPTION! @deployment #{@deployment.inspect}"
    @deployment.fail!(retryable: true) if @deployment
    super
  end

  def on_non_retryable_exception(error)
    log_for_user(:failed)
    @deployment.fail!(retryable: false) if @deployment
    super
  end

  def self.log_tag(service_deployment_id)
    ['ServiceDeploymentId', service_deployment_id].join(':')
  end

  def log_for_user(message_key, args={})
    i18n_args = {
      scope: [:undeploy_service_job],
      service_deployment_id: @service_deployment_id,
      job_id: job_id
    }.merge(args)

    JobLogService.log(
      message: I18n.t(
        message_key,
        i18n_args
      ),
      job: self,
      tag: self.class.log_tag(@service_deployment_id)
    )
  end
end
