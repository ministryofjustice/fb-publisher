class CloudPlatformAdapter
  attr_accessor :environment, :kubernetes_adapter

  def initialize(environment:, kubernetes_adapter: nil)
    @environment = environment
    @kubernetes_adapter = kubernetes_adapter || \
                          KubernetesAdapter.new(environment: environment)
  end

  def start_service(service:, tag:, container_port: 3000)
    if kubernetes_adapter.exists_in_namespace?(
      name: service.slug,
      type: 'deployment'
    )
      kubernetes_adapter.set_image(
        deployment_name: service.slug,
        container_name: service.slug,
        image: tag
      )
    end
    kubernetes_adapter.run(
      tag: tag,
      name: service.slug,
      port: container_port
    )

    # no node port needed with an ingress rule, but we still need to
    # run expose to create a service
    kubernetes_adapter.expose_deployment(
      name: service.slug,
      port: container_port,
      target_port: container_port
    )
  end


  # can be called before the service is deployed
  def url_for(service:)
    environment.url_for(service)
  end

  def setup_service(
    service:,
    deployment:,
    config_dir:,
    container_port: 3000,
    image: default_runner_image_ref
  )
    kubernetes_adapter.create_deployment(
      config_dir: config_dir,
      name: service.slug,
      container_port: container_port,
      image: image,
      json_repo: service.git_repo_url,
      commit_ref: deployment.commit_sha,
      config_map_name: kubernetes_adapter.config_map_name(service: service)
    )

    begin
      kubernetes_adapter.expose_deployment(
        name: service.slug,
        port: container_port,
        target_port: container_port
      )
    rescue CmdFailedError => e
      Rails.logger.info "expose_deployment failed: #{e}\nIgnoring"
    end

    begin
      create_ingress_rule(
        service: service,
        config_dir: config_dir
      )
    rescue CmdFailedError => e
      Rails.logger.info "create_ingress_rule failed: #{e}\nIgnoring"
    end
  end

  def configure_env_vars(service:, config_dir:, system_config: {})
    env_vars = ServiceConfigParam.key_value_pairs(
      service.service_config_params
      .where(environment_slug: environment.slug)
      .order(:name)
    )

    begin
      kubernetes_adapter.set_environment_vars(
        vars: env_vars.merge(system_config),
        service: service,
        config_dir: config_dir
      )
    rescue CmdFailedError => e
      Rails.logger.info "set_environment_vars failed: #{e}\nIgnoring"
    end
  end

  def create_ingress_rule(service:, config_dir:)
    url = url_for(service: service)

    kubernetes_adapter.create_ingress_rule(
      service_slug: service.slug,
      config_dir: config_dir,
      hostname: URI.parse(url).host
    )
  end

  ##############################################################
  # Everything below here is the same for the minikube adapter
  # TODO: refactor for DRY-ness!
  ##############################################################

  def service_url(service:)
    kubernetes_adapter.service_url(
      service: service
    )
  end



  def service_is_running?(service:)
    kubernetes_adapter.exists_in_namespace?(
      name: service.slug,
      type: 'service'
    )
  end

  def deployment_exists?(service:)
    kubernetes_adapter.exists_in_namespace?(
      name: service.slug,
      type: 'deployment'
    )
  end

  def delete_deployment(service:)
    kubernetes_adapter.delete_deployment(
      name: kubernetes_adapter.deployment_name(service: service)
    )
  end

  def stop_service(service:)
    if service_is_running?(service: service)
      kubernetes_adapter.delete_service(
        name: service.slug
      )
    end
    if deployment_exists?(service: service)
      delete_deployment(service: service)
    end
  end

  def delete_pods(service: service)
    kubernetes_adapter.delete_pods(
      label: "run=#{service.slug}"
    )
  end

end
