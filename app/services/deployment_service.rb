class DeploymentService
  def self.service_status(service, environment_slugs: ServiceEnvironment.all_slugs)
    environment_slugs.map do |env_slug|
      last_status(service: service, environment_slug: env_slug) || \
        empty_deployment(service: service, environment_slug: env_slug)
    end
  end

  # TODO: implement properly when we have services running
  def self.last_status(service:, environment_slug:)
    ServiceDeployment.latest( service_id: service.id,
                              environment_slug: environment_slug)
  end

  def self.list(service:, environment_slug:, limit: 10, offset: 0, order: 'created_at', dir: 'desc')
    ServiceDeployment.where(
      service_id: service.id,
      environment_slug: environment_slug
    )
    .order([order, dir].join(' '))
    .limit(limit)
    .offset(offset)
  end

  private

  def self.empty_deployment(service:, environment_slug:)
    ServiceDeployment.new(
      service: service,
      environment_slug: environment_slug
    )
  end
end
