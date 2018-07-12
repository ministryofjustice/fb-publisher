class DeployServiceJob < ApplicationJob
  queue_as :default

  def perform(service_deployment_id:)
    @service_deployment_id = service_deployment_id
    @deployment = ServiceDeployment.find(service_deployment_id)

    @deployment.update_status(:running)

    config_dir = File.join(temp_dir, 'config')
    @deployment.update_attributes(
      commit_sha: VersionControlService.checkout(
        repo_url: @deployment.service.git_repo_url,
        ref: @deployment.commit_sha
      )
    )

    DeploymentService.setup_service(
      config_dir: config_dir,
      environment_slug: @deployment.environment_slug,
      service: @deployment.service,
      deployment: @deployment
    )

    DeploymentService.configure_env_vars(
      config_dir: config_dir,
      environment_slug: @deployment.environment_slug,
      service: @deployment.service,
      deployment: @deployment
    )

    @deployment.complete!
  end

  def on_retryable_exception(error)
    logger.warn "RETRYABLE EXCEPTION! @deployment #{@deployment.inspect}"
    @deployment.fail!(retryable: true) if @deployment
    super
  end

  def on_non_retryable_exception(error)
    @deployment.fail!(retryable: false) if @deployment
    super
  end
end
