class ServiceDeploymentStatus
  attr_accessor :service_id, :service_slug, :status_environment_slug, :status_url, :deployment_id, :deployment_status

  def initialize(service:, environment_slug:, deployment:)
    self.service_id = service.id
    self.service_slug = service.slug
    self.deployment_id = deployment.nil? ? nil : deployment.id
    self.deployment_status = deployment.nil? ? nil : deployment.status
    self.status_environment_slug = environment_slug.to_s
    self.status_url = DeploymentService.url_for(service: service, environment_slug: environment_slug)
  end

  def self.all(service)
    ServiceEnvironment.all_slugs.map do |env_slug|
      ServiceDeploymentStatus.new(
        service: service,
        environment_slug: env_slug,
        deployment: DeploymentService.last_successful_deployment(
          service: service,
          environment_slug: env_slug
        )
      )
    end
  end
end
