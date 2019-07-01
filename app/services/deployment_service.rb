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

  def self.adapter_for(environment_slug)
    environment = ServiceEnvironment.find(environment_slug)
    name = environment.deployment_adapter
    klass = [name, 'adapter'].join('_').classify.constantize
    klass.new(environment: environment)
  end

  def self.service_tag(
    environment_slug:,
    service:,
    version: 'latest',
    repository_scope: ENV['REMOTE_DOCKER_USERNAME']
  )
    name = ['fb', service.slug, environment_slug].join('-')
    scoped = [repository_scope, name].join('/')
    versionned= [scoped, version].join(':')
  end

  def self.setup_service(
    environment_slug:,
    service:,
    deployment:,
    config_dir:,
    container_port: 3000
  )
    FileUtils.mkdir_p(config_dir)

    adapter = adapter_for(environment_slug)
    # generate the pod config
    adapter.setup_service(
      service: service,
      deployment: deployment,
      config_dir: config_dir,
      container_port: container_port
    )
  end

  def self.expose(
    environment_slug:,
    service:,
    config_dir:,
    container_port: 3000
  )
    adapter = adapter_for(environment_slug)
    adapter.expose(service: service, config_dir: config_dir, container_port: container_port)
  end

  def self.configure_env_vars(environment_slug:, service:, config_dir:, deployment:)
    FileUtils.mkdir_p(config_dir)
    adapter = adapter_for(environment_slug)

    adapter.configure_env_vars(
      config_dir: config_dir,
      service: service,
      system_config: system_config_for(
        service: service,
        deployment: deployment,
        environment_slug: environment_slug
      )
    )
  end

  def self.create_service_token_secret(environment_slug:, service:, config_dir:)
    adapter = adapter_for(environment_slug)
    adapter.create_service_token_secret(
      config_dir: config_dir,
      service: service,
      environment_slug: environment_slug
    )
  end

  def self.system_config_for(service:, deployment:, environment_slug:)
    {
      'SERVICE_PATH' => File.join('/usr/app/', deployment.json_sub_dir.to_s),
      'BIND_IP' => '0.0.0.0'
    }
  end

  def self.stop_service(environment_slug:, service:)
    adapter = adapter_for(environment_slug)
    adapter.stop_service(
      service: service
    )
  end

  def self.stop_service_by_slug(environment_slug:, slug:)
    adapter = adapter_for(environment_slug)
    adapter.stop_service_by_slug(slug: slug)
  end

  def self.start_service(environment_slug:, service:, tag:)
    adapter = adapter_for(environment_slug)
    adapter.start_service(
      service: service,
      tag: tag
    )
  end

  def self.restart_service(service:, environment_slug:)
    adapter = adapter_for(environment_slug)
    adapter.patch_deployment(name: service.slug)
  end

  def self.url_for(environment_slug:, service:)
    adapter = adapter_for(environment_slug)
    begin
      adapter.url_for(
        service: service
      )
    rescue CmdFailedError => e
      # might not have been deployed yet
      nil
    end
  end

  def self.last_successful_deployment(service:, environment_slug:)
    ServiceDeployment.where(service: service,
                            environment_slug: environment_slug,
                            status: 'completed').order(completed_at: :desc).first
  end

  def self.create_network_policy(config_dir:, environment_slug:)
    adapter = adapter_for(environment_slug)
    adapter.create_network_policy(config_dir: config_dir,
                                  environment_slug: environment_slug)
  end

  private

  def self.empty_deployment(service:, environment_slug:)
    ServiceDeployment.new(
      service: service,
      environment_slug: environment_slug
    )
  end
end
