# Takes advantage of the sometimes-more-friendly minikube layer
# where possible, delegates to KubernetesAdapter where needed
class MinikubeAdapter
  def self.configure_env_vars(config_dir:, environment_slug:, service:, system_config: {})
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
  end



  # TODO: find a less brute-force way of doing this!
  # We want rolling zero-downtime updates, and this is
  # definitely not that
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

  def self.delete_deployment(environment_slug:, service:)
    environment = ServiceEnvironment.find(environment_slug)
    KubernetesAdapter.delete_deployment(
      name: KubernetesAdapter.deployment_name(service: service, environment_slug: environment_slug),
      namespace: environment.namespace,
      context: environment.kubectl_context
    )
  end


  def self.start_service(environment_slug:, service:, tag:, container_port: 3000, host_port: 8080)
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
      port: container_port,
      image_pull_policy: 'ifNotPresent'
    )

    KubernetesAdapter.expose_node_port(
      name: service.slug,
      namespace: environment.namespace,
      context: environment.kubectl_context,
      container_port: container_port,
      host_port: host_port
    )
  end

  # we don't set up ingress for minikube, we just use node ports
  # so we have to query for the actual urls
  def self.url_for(service:, environment_slug:, timeout: 2)
    environment = ServiceEnvironment.find(environment_slug)
    ShellAdapter.output_of(
      'minikube',
      'service',
      '--url',
      '--wait',
      timeout,
      '--interval',
      1,
      service.slug,
      '--namespace',
      environment.namespace
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
      KubernetesAdapter.expose_node_port(
        name: service.slug,
        container_port: container_port,
        host_port: container_port,
        namespace: environment.namespace,
        context: environment.kubectl_context
      )
    rescue CmdFailedError => e
      puts("cmd failed, but no problem - ignoring: #{e}")
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

  private

  def self.default_private_key_path
    "~/.minikube/machines/minikube/id_rsa"
  end

  def self.ssh_cmd(cmd_to_run: nil, private_key_path: default_private_key_path)
    ShellAdapter.build_cmd(
      executable: 'ssh',
      args: [
        '-o UserKnownHostsFile=/dev/null',
        '-o StrictHostKeyChecking=no',
        '-o LogLevel=quiet',
        "-i #{private_key_path}",
        'docker@$(minikube ip)',
        cmd_to_run
      ]
    )
  end
end
