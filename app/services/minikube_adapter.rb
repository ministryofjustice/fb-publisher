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

  def self.start(environment_slug:, service:, tag:, container_port: 3000, host_port: 8080)
    environment = ServiceEnvironment.find(environment_slug)

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
