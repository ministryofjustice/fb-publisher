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

  def self.service_tag(environment_slug:, service:, version: 'latest', repository_scope: ENV['REMOTE_DOCKER_USERNAME'])
    name = ['fb', service.slug, environment_slug].join('-')
    scoped = [repository_scope, name].join('/')
    versionned= [scoped, version].join(':')
  end

  # TODO: better version mgmt! Something semantic, or the hash?
  def self.build(environment_slug:, service:, json_dir:, tag: nil)

    tag ||= service_tag(environment_slug: environment_slug,
                        service: service,
                        version: GitService.current_commit_sha(dir: json_dir))

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

  def self.configure(environment_slug:, service:, config_dir:)
    FileUtils.mkdir_p(config_dir)
    adapter = adapter_for(environment_slug)
    adapter.configure(
      config_dir: config_dir,
      environment_slug: environment_slug,
      service: service
    )
  end

  def self.restart(environment_slug:, service:, tag:)
    adapter = adapter_for(environment_slug)
    if adapter.service_is_running?(
      environment_slug: environment_slug,
      service: service
    )
      stop(environment_slug: environment_slug, service: service)
    end

    if adapter.deployment_exists?(
      environment_slug: environment_slug,
      service: service
    )
      begin
        adapter.delete_deployment(
          environment_slug: environment_slug,
          service: service
        )
      rescue CmdFailedError => e
        false
      end
    end

    start(environment_slug: environment_slug, service: service, tag: tag)
  end

  def self.stop(environment_slug:, service:)
    adapter = adapter_for(environment_slug)
    adapter.stop(
      environment_slug: environment_slug,
      service: service
    )
  end

  def self.start(environment_slug:, service:, tag:)
    adapter = adapter_for(environment_slug)
    adapter.start(
      environment_slug: environment_slug,
      service: service,
      tag: tag
    )
  end

  def self.url_for(environment_slug:, service:)
    adapter = adapter_for(environment_slug)
    begin
      adapter.url_for(
        environment_slug: environment_slug,
        service: service
      )
    rescue CmdFailedError => e
      # might not have been deployed yet
      nil
    end
  end

  private

  def self.empty_deployment(service:, environment_slug:)
    ServiceDeployment.new(
      service: service,
      environment_slug: environment_slug
    )
  end
end
