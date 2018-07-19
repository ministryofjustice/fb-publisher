class KubernetesAdapter
  def self.set_environment_vars(vars: {}, service:, config_dir:, environment_slug:)
    environment = ServiceEnvironment.find(environment_slug)
    namespace = environment.namespace
    config_file_path = File.join(config_dir, 'config-map.yml')

    File.open(config_file_path, 'w+') do |f|
      f << config_map(vars: vars, name: config_map_name(service: service), namespace: namespace)
    end
    create_or_update_config_map(
      context: environment.kubectl_context,
      file: config_file_path,
      name: config_map_name(service: service),
      namespace: namespace
    )
    # apply_config_map(
    #   name: config_map_name(service: service),
    #   deployment_name: service.slug,
    #   namespace: namespace,
    #   context: environment.kubectl_context
    # )
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
      'apply',
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
    File.open(file_path, 'w+') do |f|
      f << ingress_rule(service_slug: service_slug,
                        hostname: hostname,
                        container_port: 3000)
    end

    apply_file(file: file_path, namespace: namespace, context: context)
  end

  def self.create_deployment(
      config_dir:,
      name:,
      container_port:,
      image:,
      json_repo:,
      commit_ref:,
      context:,
      namespace:,
      environment_slug:,
      config_map_name:
    )
    file = File.join(config_dir, 'deployment.yml')
    write_config_file(
      file: file,
      content: deployment(
          name: name,
          container_port: container_port,
          image: image,
          json_repo: json_repo,
          commit_ref: commit_ref,
          namespace: namespace,
          config_map_name: config_map_name
      )
    )
    apply_file(file: file, namespace: namespace, context: context)
  end

  def self.create_pod(
      config_dir:,
      name:,
      container_port:,
      image:,
      json_repo:,
      commit_ref:,
      context:,
      namespace:,
      environment_slug:
    )
    file = File.join(config_dir, 'pod.yml')
    write_config_file(
      file: file,
      content: pod_with_volume(
          name: name,
          container_port: container_port,
          image: image,
          json_repo: json_repo,
          commit_ref: commit_ref,
          namespace: namespace
      )
    )
    apply_file(file: file, namespace: namespace, context: context)
  end

  def self.write_config_file(file:, content:)
    File.open(file, 'w+') do |f|
      f << content
    end
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

    apply_file(file: file, namespace: namespace, context: context)
    # ShellAdapter.exec(
    #   kubectl_binary,
    #   'create',
    #   'configmap',
    #   name,
    #   "--from-file=#{file}",
    #   std_args(namespace: namespace, context: context)
    # )
  end

  def self.run(tag:, name:, namespace:, context:, port: 3000, image_pull_policy: 'Always')
    ShellAdapter.exec(
      kubectl_binary,
      'run',
      "--image=#{tag}",
      name,
      "--port=#{port}",
      '--image-pull-policy',
      image_pull_policy,
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

  def self.expose_deployment( name:, port:, target_port:, namespace:, context: )
    ShellAdapter.exec(
      kubectl_binary,
      'expose',
      'deployment',
      name,
      '--port',
      port,
      '--target-port',
      target_port,
      std_args(namespace: namespace, context: context)
    )
  end

  def self.delete_pods( label:, namespace:, context: )
    ShellAdapter.exec(
      kubectl_binary,
      'delete',
      'pods',
      '-l',
      label,
      std_args(namespace: namespace, context: context)
    )
  end

  private

  def self.std_args(namespace:, context:)
    " --context=#{context} --namespace=#{namespace} --token=$KUBECTL_BEARER_TOKEN"
  end

  def self.kubectl_binary
    '$(which kubectl)'
  end

  def self.timestamp_annotation
    "{\"spec\":{\"template\":{\"metadata\":{\"annotations\":{\"updated_at\":\"`date +'%s'`\"}}}}}"
  end

  def self.pod_with_volume(name:, container_port:, image:, json_repo:, commit_ref:, namespace:)
    cmd = "git clone #{json_repo} /usr/app/ && cd /usr/app && git checkout #{commit_ref}"
    <<~ENDHEREDOC
    apiVersion: v1
    kind: Pod
    metadata:
      name: #{name}
      namespace: #{namespace}
    spec:
      initContainers:
      - name: clone-git-repo-into-volume
        image: radial/busyboxplus:git
        command: ["/bin/sh", "-c", "#{cmd}"]
        volumeMounts:
        - mountPath: /usr/app
          name: json-repo
      containers:
      - name: #{name}
        image: #{image}
        imagePullPolicy: Always
        ports:
        - containerPort: #{container_port}
        volumeMounts:
        - name: json-repo
          mountPath: /usr/app

      volumes:
      - emptyDir: {}
        name: json-repo
    ENDHEREDOC
  end

  def self.deployment(name:, namespace:, json_repo:, commit_ref:, container_port:, image:, config_map_name:)
    cmd = "git clone #{json_repo} /usr/app/ && cd /usr/app && git checkout #{commit_ref}"
    <<~ENDHEREDOC
    apiVersion: apps/v1beta2
    kind: Deployment
    metadata:
      name: #{name}
      namespace: #{namespace}
      labels:
        run: #{name}
    spec:
      replicas: 2
      selector:
        matchLabels:
          run: #{name}
      template:
        metadata:
          labels:
            run: #{name}
        spec:
          initContainers:
          - name: clone-git-repo-into-volume
            image: radial/busyboxplus:git
            command: ["/bin/sh", "-c", "#{cmd}"]
            volumeMounts:
            - mountPath: /usr/app
              name: json-repo
          containers:
          - name: #{name}
            envFrom:
            - configMapRef:
                name: #{config_map_name}
            image: #{image}
            ports:
            - containerPort: #{container_port}
            volumeMounts:
            - name: json-repo
              mountPath: /usr/app

          volumes:
          - emptyDir: {}
            name: json-repo
    ENDHEREDOC
  end

  def self.config_map(vars: {}, name:, namespace:)
    <<~ENDHEREDOC
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: #{name}
      namespace: #{namespace}
    data:
    #{vars.map {|k,v| "  #{k}: #{v}" }.join("\n")}
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
