class KubernetesAdapter
  def self.set_environment_vars(vars: {}, service:, config_dir:, environment_slug:)
    environment = ServiceEnvironment.find(environment_slug)
    namespace = environment.namespace
    config_file_path = File.join(config_dir, 'config-map.yml')

    File.open(config_file_path, 'w+') do |f|
      f << config_map(vars: vars, name: name, namespace: namespace)
    end
    create_or_update_config_map(
      context: environment.kubectl_context,
      file: config_file_path,
      name: config_map_name(service: service),
      namespace: namespace
    )
    patch_deployment(
      context: environment.kubectl_context,
      name: deployment_name(service: service, environment_slug: environment_slug),
      namespace: namespace
    )
  end

  def self.namespace_exists?(namespace:, context:)
    begin
      ShellAdapter.exec(
        kubectl_binary,
        'get',
        'namespaces',
        namespace,
        "--context=#{context}"
      )
    rescue CmdFailedError => e
      false
    end
  end

  def self.configmap_exists?(name:, namespace:, context:)
    begin
      ShellAdapter.exec(
        kubectl_binary,
        'get',
        'configmaps',
        name,
        std_args(namespace: namespace, context: context)
      )
    rescue CmdFailedError => e
      false
    end
  end

  # just writes an updated timestamp annotation -
  # quickest, smoothest and easiest way to refresh a deployment
  # so that it can pick up new configmaps, etc
  def self.patch_deployment(name:, namespace:, context:)
    ShellAdapter.exec(
      kubectl_binary,
      'patch',
      'deployment',
      name,
      std_args(namespace: namespace, context: context),
      '-p',
      timestamp_annotation
    )
  end

  # see https://blog.zkanda.io/updating-a-configmap-secrets-in-kubernetes/
  def self.create_or_update_config_map(file:, name:, namespace:, context:)
    args = [
      'create',
      'configmap',
      name,
      "--from-file=#{file}",
      std_args(namespace: namespace, context: context)
    ]
    pipe = nil

    if configmap_exists?(name: name, namespace: namespace, context: context)
      args += ['--dry-run', '-o', 'yaml']
      pipe = "kubectl replace -f -"
    end
    cmd = ShellAdapter.build_cmd(executable: kubectl_binary, args: args, pipe_to: pipe)
    ShellAdapter.exec(cmd)
  end

  def self.run(tag:, name:, namespace:, context:, port: 3000)
    ShellAdapter.exec(
      kubectl_binary,
      'run',
      "--image=#{tag}",
      name,
      "--port=#{port}",
      '--image-pull-policy=IfNotPresent',
      std_args(namespace: namespace, context: context)
    )
  end

  def self.expose_node_port( name:, namespace:, context:, container_port: 3000, host_port: )
    ShellAdapter.exec(
      kubectl_binary,
      'expose',
      'deployment',
      name,
      "--port=#{host_port}",
      "--target-port=#{container_port}",
      '--type=NodePort',
      std_args(namespace: namespace, context: context)
    )
  end

  def self.config_map_name(service:)
    ['fb', service.slug, 'config-map'].join('-')
  end

  def self.deployment_name(service:, environment_slug:)
    # ['fb', service.slug, 'dpl'].join('-')

    # if we're using kubectl run shorthand, then the
    # deployment name is the service name
    service.slug
  end

  private

  def self.std_args(namespace:, context:)
    "--context=#{context} --namespace=#{namespace}"
  end

  def self.kubectl_binary
    '$(which kubectl)'
  end

  def self.timestamp_annotation
    "{\"spec\":{\"template\":{\"metadata\":{\"annotations\":{\"updated_at\":\"`date +'%s'`\"}}}}}"
  end

  def self.config_map(vars: {}, name:, namespace:)
    <<~ENDHEREDOC
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: #{name}
      namespace: #{namespace}
    data:
      #{vars.map {|k,v| "  #{k}: #{v}" }.join('\n')}
    ENDHEREDOC
  end
end
