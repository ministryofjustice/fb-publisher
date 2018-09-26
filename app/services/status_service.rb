class StatusService
  def self.service_status(service, environment_slugs: ServiceEnvironment.all_slugs)
    environment_slugs.map do |env_slug|
      last_status(service: service, environment_slug: env_slug) || \
        empty_check(service: service, environment_slug: env_slug)
    end
  end

  # TODO: implement properly when we have services running
  def self.last_status(service:, environment_slug:)
    ServiceStatusCheck.latest( service_id: service.id,
                               environment_slug: environment_slug)
  end

  def self.check(service:, environment_slug:, timeout: 5)
    ServiceStatusCheck.execute!(
      environment_slug: environment_slug,
      service: service,
      timeout: timeout
    )
  end

  def self.check_in_parallel( service:,
                              environment_slugs: ServiceEnvironment.all_slugs,
                              timeout: 5)
    ServiceStatusCheck.execute_many!(
      service: service,
      environment_slugs: environment_slugs,
      timeout: timeout
    )

  end

  def self.service_status_deployment(service:)
    status = StatusService.service_status(service)
    deployments = DeploymentService.service_status(service)
    service_status_collection(status: status, deployments: deployments)
  end

  private

  def self.empty_check(service:, environment_slug:)
    check = ServiceStatusCheck.new(
      service: service,
      environment_slug: environment_slug
    )
    check.url = check.url_from_env_and_service
    check
  end

  def self.service_status_collection(status:, deployments:)
    status_collection = []
    status.each do |s|
      deployments.each do |d|
        next unless d.environment_slug == s.environment_slug
        status_collection << { environment_slug: s.environment_slug,
                               status: s.status, url: s.url, timestamp: s.timestamp,
                               deployment_status: d.status, service: d.service }
      end
    end
    status_collection
  end
end
