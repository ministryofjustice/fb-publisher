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
    apply_config_map(
      name: config_map_name(service: service),
      deployment_name: service.slug,
      namespace: namespace,
      context: environment.kubectl_context
    )
    # This doesn't seem to have any effect on minikube
    if deployment_exists?(
      context: environment.kubectl_context,
      name: deployment_name(service: service, environment_slug: environment_slug),
      namespace: namespace
    )
      begin
        patch_deployment(
          context: environment.kubectl_context,
          name: deployment_name(service: service, environment_slug: environment_slug),
          namespace: namespace
        )
      rescue CmdFailedError => e
        puts 'could not patch deployment - this may not be a problem?'
      end
    end
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
      true
    rescue CmdFailedError => e
      false
    end
  end

  def self.configmap_exists?(name:, namespace:, context:)
    exists_in_namespace?( name: name, type: 'configmap',
                          namespace: namespace, context: context)
  end

  def self.deployment_exists?(name:, namespace:, context:)
    exists_in_namespace?( name: name, type: 'deployment',
                          namespace: namespace, context: context)
  end

  def self.exists_in_namespace?(name:, type:, namespace:, context:)
    begin
      ShellAdapter.exec(
        kubectl_binary,
        'get',
        type,
        name,
        std_args(namespace: namespace, context: context)
      )
      true
    rescue CmdFailedError => e
      false
    end
  end

  def self.set_image( deployment_name:, container_name:, image:, namespace:, context:)
    ShellAdapter.exec(
      kubectl_binary,
      'set',
      'image',
      "deployment/#{deployment_name}",
      "#{container_name}=#{image}",
      std_args(namespace: namespace, context: context)
    )
  end

  def self.delete_service(name:, namespace:, context:)
    ShellAdapter.exec(
      kubectl_binary,
      'delete',
      'service',
      name,
      std_args(namespace: namespace, context: context)
    )
  end

  def self.delete_deployment(name:, namespace:, context:)
    ShellAdapter.exec(
      kubectl_binary,
      'delete',
      'deployment',
      name,
      std_args(namespace: namespace, context: context)
    )
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
      "'#{timestamp_annotation}'"
    )
  end

  # see https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#-em-env-em-
  # "Import environment from a config map with a prefix"
  def self.apply_config_map(name:, deployment_name:, namespace:, context:)
    ShellAdapter.exec(
      kubectl_binary,
      'set',
      'env',
      "--from=configmap/#{name}",
      std_args(namespace: namespace, context: context),
      "deployment/#{deployment_name}"
    )
  end

  def self.apply_file(file:, namespace:, context:)
    ShellAdapter.exec(
      kubectl_binary,
      '-f',
      file,
      std_args(namespace: namespace, context: context)
    )
  end

  def self.create_ingress_rule(
    config_dir:,
    service_slug:,
    hostname:,
    container_port: 3000,
    context:,
    namespace:
  )
    file_path = File.join(config_dir, 'config-map.yml')
    File.open(config_file_path, 'w+') do |f|
      f << ingress_rule(service_slug: service_slug,
                        hostname: hostname,
                        container_port: 3000)
    end

    apply_file(file: file_path, std_args(namespace: namespace, context: context))
  end

  # see https://blog.zkanda.io/updating-a-configmap-secrets-in-kubernetes/
  def self.create_or_update_config_map(file:, name:, namespace:, context:)
    if configmap_exists?(name: name, namespace: namespace, context: context)
      ShellAdapter.exec(
        kubectl_binary,
        'delete',
        'configmap',
        name,
        std_args(namespace: namespace, context: context)
      )
    end

    ShellAdapter.exec(
      kubectl_binary,
      'create',
      'configmap',
      name,
      "--from-file=#{file}",
      std_args(namespace: namespace, context: context)
    )
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

  # given a deployed service, what is the URL defined in the actual
  # ingress rule?
  def self.service_url(service:, environment_slug:, namespace:, context:)
    services = JSON.parse(
      ShellAdapter.output_of(
        kubectl_binary,
        'get',
        'ing',
        std_args(namespace: namespace, context: context),
        '-o',
        'json'
      )
    )
    service_item = services['items'].find do |item|
      rule = item['spec']['rules'].find do |rule|
        rule['http']['paths']['backend']['serviceName'] == service.slug
      end
      rule['host']
    end
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

  def self.ingress_rule(service_slug:, hostname:, container_port: 3000)
    <<~ENDHEREDOC
    apiVersion: extensions/v1beta1
    kind: Ingress
    metadata:
      name: #{service_slug}-ingress
      annotations:
        kubernetes.io/ingress.class: "nginx"
        nginx.ingress.kubernetes.io/ssl-redirect: "true"
    spec:
      rules:
      - host: #{hostname}
        http:
          paths:
          - path: /
            backend:
              serviceName: #{service_slug}
              servicePort: #{container_port}
    ENDHEREDOC
  end
end
