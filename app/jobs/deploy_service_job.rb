class DeployServiceJob < ApplicationJob
  queue_as :default

  def perform(service_deployment_id:, json_sub_dir: nil)
    deployment = ServiceDeployment.find(service_deployment_id)

    # Check out the code
    json_dir = File.join(temp_dir, 'json')
    config_dir = File.join(temp_dir, 'config')
    GitService.clone_repo(repo_url: deployment.service.git_repo_url, to_dir: json_dir)
    GitService.checkout(ref: deployment.commit_sha, dir: json_dir)
    deployment.commit_sha = GitService.current_commit_sha(dir: json_dir, short: true)


    # if the json we want is not in the root of the repo,
    # from now on we need to work in that sub dir
    json_dir = File.join(json_dir, json_sub_dir) if json_sub_dir.present?

    built_service = DeploymentService.build(
      environment_slug: deployment.environment_slug,
      service: deployment.service,
      json_dir: json_dir
    )
    DeploymentService.push(
      image: built_service[:tag],
      environment_slug: deployment.environment_slug
    )
    DeploymentService.restart(
      environment_slug: deployment.environment_slug,
      service: deployment.service,
      tag: built_service[:tag]
    )

    DeploymentService.configure(
      config_dir: config_dir,
      environment_slug: deployment.environment_slug,
      service: deployment.service
    )
  end
end
