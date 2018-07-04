class CloudPlatformAdapter
  def self.start(environment_slug:, service:, tag:)
  end

  def self.import_image(image:, repository_scope: ENV['REMOTE_DOCKER_USERNAME'])
    LocalDockerService.push_to_dockerhub(
      tag: image,
      repository_scope: repository_scope
    )
  end

  # can be called before the service is deployed
  def self.url_for(service:, environment_slug:)
    ServiceEnvironment.find(environment_slug).url_for(service)
  end

  def self.configure(environment_slug:, service:, config_dir:, system_config: {})
    env_vars = ServiceConfigParam.key_value_pairs(
      service.service_config_params
      .where(environment_slug: environment_slug)
      .order(:name)
    )

    KubernetesAdapter.set_environment_vars(
      vars: env_vars.merge(system_config),
      service: service,
      config_dir: config_dir,
      environment_slug: environment_slug
    )

    # this is the only bit that's different for Cloud Platform vs Minikube
    KubernetesAdapter.create_ingress_rule(
      service: service,
      config_dir: config_dir,
      environment_slug: environment_slug
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

  def self.stop(environment_slug:, service:)
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

end
