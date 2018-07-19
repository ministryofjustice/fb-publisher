# Takes advantage of the sometimes-more-friendly minikube layer
# where possible, delegates to KubernetesAdapter where needed
class MinikubeAdapter
  attr_accessor :environment, :kubernetes_adapter

  def initialize(environment:, kubernetes_adapter: nil)
    @environment = environment
    @kubernetes_adapter = kubernetes_adapter || \
                          KubernetesAdapter.new(environment: environment)
  end

  def self.configure_env_vars(config_dir:, service:, system_config: {})
    env_vars = ServiceConfigParam.key_value_pairs(
      service.service_config_params
             .where(environment_slug: @environment.slug)
             .order(:name)
    )

    kubernetes_adapter.set_environment_vars(
      vars: env_vars.merge(system_config),
      service: service,
      config_dir: config_dir
    )
  end



  # TODO: find a less brute-force way of doing this!
  # We want rolling zero-downtime updates, and this is
  # definitely not that
  def self.stop_service(service:)
    if service_is_running?(service: service)
      kubernetes_adapter.delete_service(
        name: service.slug
      )
    end
    if deployment_exists?(service: service)
      delete_deployment(service: service)
    end
  end

  def self.delete_deployment(service:)
    kubernetes_adapter.delete_deployment(
      name: kubernetes_adapter.deployment_name(service: service)
    )
  end


  def self.start_service(service:, tag:, container_port: 3000, host_port: 8080)
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
      port: container_port,
      image_pull_policy: 'ifNotPresent'
    )

    kubernetes_adapter.expose_node_port(
      name: service.slug,
      container_port: container_port,
      host_port: host_port
    )
  end

  # we don't set up ingress for minikube, we just use node ports
  # so we have to query for the actual urls
  def self.url_for(service:, timeout: 2)
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

  def self.service_is_running?(service:)
    kubernetes_adapter.exists_in_namespace?(
      name: service.slug,
      type: 'service'
    )
  end

  def self.deployment_exists?(service:)
    kubernetes_adapter.exists_in_namespace?(
      name: service.slug,
      type: 'deployment'
    )
  end

  def self.setup_service(
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
      kubernetes_adapter.expose_node_port(
        name: service.slug,
        container_port: container_port,
        host_port: container_port
      )
    rescue CmdFailedError => e
      puts("cmd failed, but no problem - ignoring: #{e}")
    end
  end

  def self.delete_pods(service: service)
    kubernetes_adapter.delete_pods(
      label: "run=#{service.slug}"
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
