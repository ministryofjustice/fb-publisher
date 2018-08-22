class KubernetesAdapter
  attr_accessor :environment

  def initialize(environment:)
    @environment = environment
  end

  def set_environment_vars(vars: {}, service:, config_dir:)
    config_file_path = File.join(config_dir, 'config-map.yml')

    File.open(config_file_path, 'w+') do |f|
      f << config_map(
        vars: vars,
        name: config_map_name(service: service)
      )
    end
    create_or_update_config_map(
      file: config_file_path,
      name: config_map_name(service: service)
    )
  end

  def namespace_exists?
    begin
      ShellAdapter.exec(
        kubectl_binary,
        'get',
        'namespaces',
        @environment.namespace,
        "--context=#{@environment.context}"
      )
      true
    rescue CmdFailedError => e
      false
    end
  end

  def configmap_exists?(name:)
    exists_in_namespace?( name: name, type: 'configmap' )
  end

  def deployment_exists?(name:)
    exists_in_namespace?( name: name, type: 'deployment')
  end

  def exists_in_namespace?(name:, type:)
    begin
      ShellAdapter.exec(
        kubectl_binary,
        'get',
        type,
        name,
        std_args
      )
      true
    rescue CmdFailedError => e
      false
    end
  end

  def set_image( deployment_name:, container_name:, image:)
    ShellAdapter.exec(
      kubectl_binary,
      'set',
      'image',
      "deployment/#{deployment_name}",
      "#{container_name}=#{image}",
      std_args
    )
  end

  def delete_service(name:)
    ShellAdapter.exec(
      kubectl_binary,
      'delete',
      'service',
      name,
      std_args
    )
  end

  def delete_deployment(name:)
    ShellAdapter.exec(
      kubectl_binary,
      'delete',
      'deployment',
      name,
      std_args
    )
  end

  # just writes an updated timestamp annotation -
  # quickest, smoothest and easiest way to refresh a deployment
  # so that it can pick up new configmaps, etc
  def patch_deployment(name:)
    ShellAdapter.exec(
      kubectl_binary,
      'patch',
      'deployment',
      name,
      std_args,
      '-p',
      "'#{timestamp_annotation}'"
    )
  end

  # see https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#-em-env-em-
  # "Import environment from a config map with a prefix"
  # def apply_config_map(name:, deployment_name:)
  #   ShellAdapter.exec(
  #     kubectl_binary,
  #     'set',
  #     'env',
  #     "--from=configmap/#{name}",
  #     std_args,
  #     "deployment/#{deployment_name}"
  #   )
  # end

  def apply_file(file:)
    ShellAdapter.exec(
      kubectl_binary,
      'apply',
      '-f',
      file,
      std_args
    )
  end

  def create_ingress_rule(
    config_dir:,
    service_slug:,
    hostname:,
    container_port: 3000
  )
    file_path = File.join(config_dir, 'config-map.yml')
    File.open(file_path, 'w+') do |f|
      f << ingress_rule(service_slug: service_slug,
                        hostname: hostname,
                        container_port: 3000)
    end

    apply_file(file: file_path)
  end

  def create_deployment(
      config_dir:,
      name:,
      container_port:,
      image:,
      json_repo:,
      commit_ref:,
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
          config_map_name: config_map_name
      )
    )
    apply_file(file: file)
  end

  def create_pod(
      config_dir:,
      name:,
      container_port:,
      image:,
      json_repo:,
      commit_ref:
    )
    file = File.join(config_dir, 'pod.yml')
    write_config_file(
      file: file,
      content: pod_with_volume(
          name: name,
          container_port: container_port,
          image: image,
          json_repo: json_repo,
          commit_ref: commit_ref
      )
    )
    apply_file(file: file)
  end

  def write_config_file(file:, content:)
    File.open(file, 'w+') do |f|
      f << content
    end
  end

  # see https://blog.zkanda.io/updating-a-configmap-secrets-in-kubernetes/
  def create_or_update_config_map(file:, name:)
    if configmap_exists?(name: name)
      ShellAdapter.exec(
        kubectl_binary,
        'delete',
        'configmap',
        name,
        std_args
      )
    end

    apply_file(file: file)
  end

  def run(tag:, name:, port: 3000, image_pull_policy: 'Always')
    ShellAdapter.exec(
      kubectl_binary,
      'run',
      "--image=#{tag}",
      name,
      "--port=#{port}",
      '--image-pull-policy',
      image_pull_policy,
      std_args
    )
  end

  def expose_node_port( name:, container_port: 3000, host_port: )
    ShellAdapter.exec(
      kubectl_binary,
      'expose',
      'deployment',
      name,
      "--port=#{host_port}",
      "--target-port=#{container_port}",
      '--type=NodePort',
      std_args
    )
  end

  def config_map_name(service:)
    ['fb', service.slug, 'config-map'].join('-')
  end

  def deployment_name(service:)
    # if we're using kubectl run shorthand, then the
    # deployment name is the service name
    service.slug
  end

  # given a deployed service, what is the URL defined in the actual
  # ingress rule?
  def service_url(service:)
    services = JSON.parse(
      ShellAdapter.output_of(
        kubectl_binary,
        'get',
        'ing',
        std_args,
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

  def expose_deployment( name:, port:, target_port: )
    ShellAdapter.exec(
      kubectl_binary,
      'expose',
      'deployment',
      name,
      '--port',
      port,
      '--target-port',
      target_port,
      std_args
    )
  end

  def delete_pods( label: )
    ShellAdapter.exec(
      kubectl_binary,
      'delete',
      'pods',
      '-l',
      label,
      std_args
    )
  end

  private

  def std_args
    " --context=#{@environment.kubectl_context} --namespace=#{@environment.namespace} --token=$KUBECTL_BEARER_TOKEN"
  end

  def kubectl_binary
    '$(which kubectl)'
  end

  def timestamp_annotation
    "{\"spec\":{\"template\":{\"metadata\":{\"annotations\":{\"updated_at\":\"`date +'%s'`\"}}}}}"
  end

  def pod_with_volume(name:, container_port:, image:, json_repo:, commit_ref:)
    cmd = "git clone #{json_repo} /usr/app/ && cd /usr/app && git checkout #{commit_ref}"
    <<~ENDHEREDOC
    apiVersion: v1
    kind: Pod
    metadata:
      name: #{name}
      namespace: #{@environment.namespace}
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

  def deployment(name:, json_repo:, commit_ref:, container_port:, image:, config_map_name:)
    cmd = "git clone #{json_repo} /usr/app/ && cd /usr/app && git checkout #{commit_ref}"
    <<~ENDHEREDOC
    apiVersion: apps/v1beta2
    kind: Deployment
    metadata:
      name: #{name}
      namespace: #{@environment.namespace}
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

  def config_map(vars: {}, name:)
    <<~ENDHEREDOC
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: #{name}
      namespace: #{@environment.namespace}
    data:
    #{vars.map {|k,v| "  #{k}: #{v}" }.join("\n")}
    ENDHEREDOC
  end

  def ingress_rule(service_slug:, hostname:, container_port: 3000)
    <<~ENDHEREDOC
    apiVersion: extensions/v1beta1
    kind: Ingress
    metadata:
      name: #{service_slug}-ingress
      namespace: #{@environment.namespace}
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
