# Takes advantage of the sometimes-more-friendly minikube layer
# where possible, delegates to KubernetesAdapter where needed
class MinikubeAdapter
  def self.import_image(image:, private_key_path: default_private_key_path)
    cmd = ShellAdapter.build_cmd(
      executable: 'docker',
      args: ['save', image],
      pipe_to: ssh_cmd(cmd_to_run:  'docker load ')
    )
    ShellAdapter.exec(cmd)
  end

  def self.configure(config_dir:, environment_slug:, service:)
    env_vars = ServiceConfigParam.key_value_pairs(
      service.service_config_params
             .where(environment_slug: environment_slug)
             .order(:name)
    )
    KubernetesAdapter.set_environment_vars(
      vars: env_vars,
      service: service,
      config_dir: config_dir,
      environment_slug: environment_slug
    )
  end

  # TODO: find a less brute-force way of doing this!
  # We want rolling zero-downtime updates, and this is
  # definitely not that
  def self.stop(environment_slug:, service:)
    KubernetesAdapter.delete_service(
      name: service.slug,
      namespace: environment.namespace,
      context: environment.kubectl_context
    )
  end

  def self.start(environment_slug:, service:, tag:, container_port: 3000, host_port: 8080)
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
        image: tag
      )
    else
      KubernetesAdapter.run(
        tag: tag,
        name: service.slug,
        namespace: environment.namespace,
        context: environment.kubectl_context,
        port: container_port
      )

      KubernetesAdapter.expose_node_port(
        name: service.slug,
        namespace: environment.namespace,
        context: environment.kubectl_context,
        container_port: container_port,
        host_port: host_port
      )
    end
  end

  # we don't set up ingress for minikube, we just use node ports
  # so we have to query for the actual urls
  def self.url_for(service:, environment_slug:)
    environment = ServiceEnvironment.find(environment_slug)
    ShellAdapter.output_of(
      'minikube',
      'service',
      service.slug,
      '--namespace',
      environment.namespace,
      '--url'
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
