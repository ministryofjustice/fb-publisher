class CloudPlatformAdapter < GenericKubernetesPlatformAdapter

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
      config_map_name: kubernetes_adapter.config_map_name(service: service),
      service: service
    )

    kubernetes_adapter.create_service(service: service,
                                      config_dir: config_dir)
  end

  def expose(
    service:,
    config_dir:,
    container_port: 3000
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

  def create_network_policy(config_dir:, environment_slug:)
    @platform_environment = PLATFORM_ENV
    @deployment_environment = environment_slug

    template = File.open(Rails.root.join('config', 'k8s_templates', 'network_policy.yaml.erb'), 'r').read
    erb = ERB.new(template)
    output = erb.result(binding)
    path = "#{config_dir}/network_policy.yaml"

    File.open(path, 'w') do |f|
      f.write(output)
    end

    kubernetes_adapter.apply_file(file: path)
  end

  def create_service_monitor(service:, config_dir:, environment_slug:)
    @platform_environment = PLATFORM_ENV
    @deployment_environment = environment_slug

    template = File.open(Rails.root.join('config', 'k8s_templates', 'service_monitor.yaml.erb'), 'r').read
    erb = ERB.new(template)
    output = erb.result(binding)
    path = "#{config_dir}/service_monitor.yaml"

    File.open(path, 'w') do |f|
      f.write(output)
    end

    kubernetes_adapter.apply_file(file: path)
  end

  def create_ingress_rule(service:, config_dir:)
    url = url_for(service: service)

    kubernetes_adapter.create_ingress_rule(
      service_slug: service.slug,
      config_dir: config_dir,
      hostname: URI.parse(url).host
    )
  end

  def patch_deployment(name:)
    kubernetes_adapter.patch_deployment(name: name)
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
end
