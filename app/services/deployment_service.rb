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

  def self.adapter_for(environment_slug)
    name = ServiceEnvironment.find(environment_slug).deployment_adapter
    [name, 'adapter'].join('_').classify.constantize
  end

  def self.service_tag(environment_slug:, service:, version: 'latest')
    [['fb', service.slug, environment_slug].join('-'), version].join(':')
  end

  def self.build(environment_slug:, service:, json_dir:)
    tag = service_tag(environment_slug: environment_slug, service: service)
    LocalDockerService.build(
      tag: tag,
      json_dir: json_dir
    )
    {tag: tag}
  end

  def self.push(image:, environment_slug:)
    adapter = adapter_for(environment_slug)
    adapter.import_image(
      image: image
    )
  end

  def self.configure(environment_slug:, service:)
    adapter = adapter_for(environment_slug)
    adapter.configure(
      environment_slug: environment_slug,
      service: service
    )
  end

  def self.start(environment_slug:, service:, tag:)
    adapter.start(
      environment_slug: environment_slug,
      service: service,
      tag: built_service[:tag]
    )
  end

  private

  def self.empty_deployment(service:, environment_slug:)
    ServiceDeployment.new(
      service: service,
      environment_slug: environment_slug
    )
  end
end
