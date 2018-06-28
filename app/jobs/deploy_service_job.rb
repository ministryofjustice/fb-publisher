class DeployServiceJob < ApplicationJob
  queue_as :default

  def perform(service_deployment_id:)
    # Check out the code
    deployment = ServiceDeployment.find(service_deployment_id)
    json_dir = File.join(temp_dir, 'json')
    config_dir = File.join(temp_dir, 'config')
    GitService.clone_repo(repo_url: deployment.service.git_repo_url, to_dir: json_dir)

    built_service = DeploymentService.build(
      environment_slug: deployment.environment_slug,
      service: deployment.service,
      json_dir: json_dir
    )
    DeploymentService.push(
      image: built_service[:tag],
      environment_slug: deployment.environment_slug
    )
    DeploymentService.configure(
      config_dir: config_dir,
      environment_slug: deployment.environment_slug,
      service: deployment.service
    )
    DeploymentService.start(
      environment_slug: deployment.environment_slug,
      service: deployment.service,
      tag: built_service[:tag]
    )

  end
end
