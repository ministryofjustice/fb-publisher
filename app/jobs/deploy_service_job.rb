class DeployServiceJob < ApplicationJob
  queue_as :default

  def perform(service_deployment_id:)
    @service_deployment_id = service_deployment_id
    @deployment = ServiceDeployment.find(service_deployment_id)
    log_for_user(:starting)

    @deployment.update_status(:deploying)

    config_dir = File.join(temp_dir, 'config')

    log_for_user(:reading_commit)
    commit = VersionControlService.checkout(
      repo_url: @deployment.service.git_repo_url,
      ref: @deployment.commit_sha,
      deploy_key: @deployment.service.deploy_key
    )

    log_for_user(:writing_commit, sha: commit)
    @deployment.update(
      commit_sha: commit
    )

    log_for_user(:creating_service_token_secret)
    DeploymentService.create_service_token_secret(
      config_dir: config_dir,
      environment_slug: @deployment.environment_slug,
      service: @deployment.service,
    )

    log_for_user(:configuring_params)
    DeploymentService.configure_env_vars(
      config_dir: config_dir,
      environment_slug: @deployment.environment_slug,
      service: @deployment.service,
      deployment: @deployment
    )

    log_for_user(:deploying_service)
    DeploymentService.setup_service(
      config_dir: config_dir,
      environment_slug: @deployment.environment_slug,
      service: @deployment.service,
      deployment: @deployment
    )

    log_for_user(:exposing)
    DeploymentService.expose(
      config_dir: config_dir,
      environment_slug: @deployment.environment_slug,
      service: @deployment.service
    )

    log_for_user(:creating_network_policy)
    DeploymentService.create_network_policy(
      config_dir: config_dir,
      environment_slug: @deployment.environment_slug
    )

    log_for_user(:creating_service_monitor)
    DeploymentService.create_service_monitor(
      service: @deployment.service,
      config_dir: config_dir,
      environment_slug: @deployment.environment_slug
    )

    log_for_user(:restarting)
    DeploymentService.restart_service(
      environment_slug: @deployment.environment_slug,
      service: @deployment.service
    )

    log_for_user(:complete)
    @deployment.complete!

    notify_first_live_publish if ENV['SLACK_PUBLISH_WEBHOOK']
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
      scope: [:deploy_service_job],
      service_deployment_id: @service_deployment_id,
      job_id: job_id
    }.merge(args)

    JobLogService.log(
      message: I18n.t(
        message_key,
        **i18n_args
      ),
      job: self,
      tag: self.class.log_tag(@service_deployment_id)
    )
  end

  def notify_first_live_publish
    prod_deployments = @deployment.service
                                  .service_deployments
                                  .where(environment_slug: 'production')
                                  .where(status: 'completed')

    # current service deployment job could be to production in which case if
    # there is only one then it's the first time
    if prod_deployments.count == 1
      NotificationService.notify(
        "#{@deployment.service.name} has been published to Live for the first time"
      )
    end
  end
end
