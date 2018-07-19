class CloudPlatformAdapter
  def self.start_service(environment_slug:, service:, tag:, container_port: 3000)
    environment = ServiceEnvironment.find(environment_slug)

    if KubernetesAdapter.exists_in_namespace?(
      name: service.slug,
      type: 'deployment',
      namespace: environment.namespace,
      context: environment.kubectl_context
    )
      KubernetesAdapter.set_image(
        deployment_name: service.slug,
        container_name: service.slug,
        image: tag,
        namespace: environment.namespace,
        context: environment.kubectl_context
      )
    end
    KubernetesAdapter.run(
      tag: tag,
      name: service.slug,
      namespace: environment.namespace,
      context: environment.kubectl_context,
      port: container_port
    )

    # no node port needed with an ingress rule, but we still need to
    # run expose to create a service
    KubernetesAdapter.expose_deployment(
      name: service.slug,
      port: container_port,
      target_port: container_port,
      namespace: environment.namespace,
      context: environment.kubectl_context
    )
  end

  
  # can be called before the service is deployed
  def self.url_for(service:, environment_slug:)
    ServiceEnvironment.find(environment_slug).url_for(service)
  end

  def self.setup_service(
    environment_slug:,
    service:,
    deployment:,
    config_dir:,
    container_port: 3000,
    image: default_runner_image_ref
  )
    environment = ServiceEnvironment.find(environment_slug)
    KubernetesAdapter.create_deployment(
      config_dir: config_dir,
      name: service.slug,
      container_port: container_port,
      image: image,
      json_repo: service.git_repo_url,
      commit_ref: deployment.commit_sha,
      context: environment.kubectl_context,
      namespace: environment.namespace,
      environment_slug: environment_slug,
      config_map_name: KubernetesAdapter.config_map_name(service: service)
    )

    begin
      KubernetesAdapter.expose_deployment(
        name: service.slug,
        port: container_port,
        target_port: container_port,
        namespace: environment.namespace,
        context: environment.kubectl_context
      )
    rescue CmdFailedError => e
      Rails.logger.info "expose_deployment failed: #{e}\nIgnoring"
    end

    begin
      create_ingress_rule(
        service: service,
        environment_slug: environment_slug,
        config_dir: config_dir
      )
    rescue CmdFailedError => e
      Rails.logger.info "create_ingress_rule failed: #{e}\nIgnoring"
    end
  end

  def self.configure_env_vars(environment_slug:, service:, config_dir:, system_config: {})
    env_vars = ServiceConfigParam.key_value_pairs(
      service.service_config_params
      .where(environment_slug: environment_slug)
      .order(:name)
    )

    begin
      KubernetesAdapter.set_environment_vars(
        vars: env_vars.merge(system_config),
        service: service,
        config_dir: config_dir,
        environment_slug: environment_slug
      )
    rescue CmdFailedError => e
      Rails.logger.info "set_environment_vars failed: #{e}\nIgnoring"
    end
  end

  def self.create_ingress_rule(service:, environment_slug:, config_dir:)
    url = url_for(service: service, environment_slug: environment_slug)
    environment = ServiceEnvironment.find(environment_slug)

    KubernetesAdapter.create_ingress_rule(
      service_slug: service.slug,
      config_dir: config_dir,
      hostname: URI.parse(url).host,
      context: environment.kubectl_context,
      namespace: environment.namespace
    )
  end

  ##############################################################
  # Everything below here is the same for the minikube adapter
  # TODO: refactor for DRY-ness!
  ##############################################################

  def self.service_url(service:, environment_slug:)
    environment = ServiceEnvironment.find(environment_slug)
    KubernetesAdapter.service_url(
      service: service,
      environment_slug: environment_slug,
      context: environment.kubectl_context,
      namespace: environment.namespace
    )
  end



  def self.service_is_running?(environment_slug:, service:)
    environment = ServiceEnvironment.find(environment_slug)
    KubernetesAdapter.exists_in_namespace?(
      name: service.slug,
      type: 'service',
      namespace: environment.namespace,
      context: environment.kubectl_context
    )
  end

  def self.deployment_exists?(environment_slug:, service:)
    environment = ServiceEnvironment.find(environment_slug)
    KubernetesAdapter.exists_in_namespace?(
      name: service.slug,
      type: 'deployment',
      namespace: environment.namespace,
      context: environment.kubectl_context
    )
  end

  def self.delete_deployment(environment_slug:, service:)
    environment = ServiceEnvironment.find(environment_slug)
    KubernetesAdapter.delete_deployment(
      name: KubernetesAdapter.deployment_name(service: service, environment_slug: environment_slug),
      namespace: environment.namespace,
      context: environment.kubectl_context
    )
  end

  def self.stop_service(environment_slug:, service:)
    environment = ServiceEnvironment.find(environment_slug)
    if service_is_running?(service: service, environment_slug: environment_slug)
      KubernetesAdapter.delete_service(
        name: service.slug,
        namespace: environment.namespace,
        context: environment.kubectl_context
      )
    end
    if deployment_exists?(service: service, environment_slug: environment_slug)
      delete_deployment(service: service, environment_slug: environment_slug)
    end
  end

  def self.delete_pods(environment_slug:, service: service)
    environment = ServiceEnvironment.find(environment_slug)
    KubernetesAdapter.delete_pods(
      label: "run=#{service.slug}",
      namespace: environment.namespace,
      context: environment.kubectl_context
    )
  end

end
