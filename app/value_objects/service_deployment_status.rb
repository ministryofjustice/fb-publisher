class ServiceDeploymentStatus
  attr_accessor :service_id, :service_slug, :status_environment_slug,
                :service_status, :status_url, :status_timestamp,
                :deployment_id, :deployment_status

  def initialize(service:, status_service:, deployment:)
    self.service_id = service.id
    self.service_slug = service.slug
    self.status_environment_slug = status_service.environment_slug
    self.service_status = status_service.status
    self.status_url = status_service.url
    self.status_timestamp = status_service.timestamp
    self.deployment_id = deployment.nil? ? nil : deployment.id
    self.deployment_status = deployment.nil? ? nil : deployment.status
  end

  def self.all(service)
    service_deployments = []

    StatusService.service_status(service).each do |status_service|
      deployment = DeploymentService.last_successful_deployment(
        service: service, environment_slug: status_service.environment_slug)

      service_deployments << ServiceDeploymentStatus.new(service: service,
                                                         status_service: status_service,
                                                         deployment: deployment)
    end
    service_deployments
  end
end
