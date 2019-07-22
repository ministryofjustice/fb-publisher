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
    filedata = File.read(config_file_path)
    create_or_update_config_map(
      file: config_file_path,
      name: config_map_name(service: service)
    )
  end

  def create_secret(name:, key_ref:, value:, config_dir:)
    config_file_path = File.join(config_dir, 'service-token-secret.yml')

    write_config_file(
      file: config_file_path,
      content: secret(
        name: name,
        key_ref: key_ref,
        value: value,
      )
    )

    apply_file(file: config_file_path)
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

  def delete_ingress(name:)
    ShellAdapter.exec(
      kubectl_binary,
      'delete',
      'ingresses.extensions',
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
      config_map_name:,
      service:
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
          config_map_name: config_map_name,
          service: service
      )
    )
    apply_file(file: file)
  end

  def create_service(config_dir:, service:)
    template = File.open(Rails.root.join('config', 'k8s_templates', 'service.yaml.erb'), 'r').read
    erb = ERB.new(template)
    output = erb.result(binding)
    path = "#{config_dir}/service.yml"

    File.open(path, 'w') do |f|
      f.write(output)
    end

    apply_file(file: path)
  end

  def write_config_file(file:, content:)
    FileUtils.mkdir_p(File.dirname(file))
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
    "{\"spec\":{\"template\":{\"metadata\":{\"annotations\":{\"updated_at\":\"#{Time.now.to_i}\"}}}}}"
  end

  def secret(name:, key_ref:, value:)
    <<~ENDHEREDOC
    apiVersion: v1
    data:
      #{key_ref}: #{Base64.encode64(value)}
    kind: Secret
    metadata:
      name: #{name}
      namespace: #{@environment.namespace}
    ENDHEREDOC
  end

  def deployment(name:, json_repo:, commit_ref:, container_port:, image:, config_map_name:, service:)
    deploy_key = service.deploy_key

    if deploy_key.present?
      cmd = "mkdir ~/.ssh && echo '#{deploy_key}' > ~/.ssh/deploy_key && cat ~/transform_deploy_key.rb && ~/transform_deploy_key.rb ~/.ssh/deploy_key ~/.ssh/deploy_key && echo 'HERE' && cat ~/.ssh/deploy_key && chmod 0600 ~/.ssh/deploy_key && ssh-keyscan -H github.com > ~/.ssh/known_hosts && GIT_SSH_COMMAND='ssh -i ~/.ssh/deploy_key' git clone #{json_repo} /usr/app/ && cd /usr/app && git checkout #{commit_ref}"
    else
      cmd = "git clone #{json_repo} /usr/app/ && cd /usr/app && git checkout #{commit_ref}"
    end

    resourcing_service = ResourcingService.new(service: service,
                                               environment_slug: @environment.slug)

    <<~ENDHEREDOC
    apiVersion: apps/v1beta2
    kind: Deployment
    metadata:
      name: #{name}
      namespace: #{@environment.namespace}
      labels:
        run: #{name}
    spec:
      replicas: #{resourcing_service.deployment_replicas}
      selector:
        matchLabels:
          run: #{name}
      template:
        metadata:
          labels:
            run: #{name}
        spec:
          initContainers:
          - name: init-clone-repo
            image: asmega/deploy:latest
            securityContext:
              runAsUser: 1001
            command: ["/bin/sh", "-c", "#{cmd}"]
            volumeMounts:
            - mountPath: /usr/app
              name: json-repo
            - mountPath: /test-volume
              name: test-volume
          containers:
          - name: #{name}
            securityContext:
              runAsUser: 1001
            envFrom:
            - configMapRef:
                name: #{config_map_name}
            env:
              - name: USER_DATASTORE_URL
                value: #{@environment.user_datastore_url}
              - name: USER_FILESTORE_URL
                value: #{@environment.user_filestore_url}
              - name: SUBMITTER_URL
                value: #{@environment.submitter_url}
              - name: SERVICE_SLUG
                value: #{name}
              - name: FORM_URL
                value: #{@environment.url_for(service).gsub(/\/*\z/, '')}
              - name: PLATFORM_ENV
                value: #{ENV['PLATFORM_ENV']}
              - name: DEPLOYMENT_ENV
                value: #{@environment.slug}
              - name: SENTRY_DSN
                value: #{ENV['RUNNER_SENTRY_DSN']}
            image: #{image}
            imagePullPolicy: Always
            ports:
            - containerPort: #{container_port}
            resources:
               limits:
                cpu: #{resourcing_service.limits_cpu}
                memory: #{resourcing_service.limits_memory}
               requests:
                cpu: #{resourcing_service.requests_cpu}
                memory: #{resourcing_service.requests_memory}
            readinessProbe:
              httpGet:
                path: /ping.json
                port: #{container_port}
              initialDelaySeconds: 5
              periodSeconds: 5
              successThreshold: 1
            volumeMounts:
            - name: json-repo
              mountPath: /usr/app
            - name: test-volume
              mountPath: /test-volume
          volumes:
          - emptyDir: {}
            name: json-repo
          - emptyDir: {}
            name: test-volume

    ENDHEREDOC
  end

  def config_map(vars: {}, name:)
    # Mapping of vars ensures that all values are quoted to ensure that
    # characters such as { do not cause the resulting YAML to be invalid
    # NB. if this method is used to generate config maps that contain numbers
    # this will need updating accordingly
    <<~ENDHEREDOC
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: #{name}
      namespace: #{@environment.namespace}
    data:
    #{vars.map {|k,v| "  #{k}: \"#{v.gsub '"', '\"'}\"" }.join("\n")}
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
        nginx.ingress.kubernetes.io/custom-http-errors: "400, 401, 403, 404, 500, 503"
    spec:
      tls:
        - hosts:
          - #{hostname}
          secretName: tls-certificate
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
