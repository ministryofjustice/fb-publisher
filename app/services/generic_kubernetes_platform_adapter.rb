class GenericKubernetesPlatformAdapter
  attr_accessor :environment, :kubernetes_adapter

  def initialize(environment: nil, kubernetes_adapter: nil)
    @environment = environment
    @kubernetes_adapter = kubernetes_adapter || \
                          KubernetesAdapter.new(environment: environment)
  end

  def configure_env_vars(service:, config_dir:, system_config: {})
    env_vars = ServiceConfigParam.key_value_pairs(
      service.service_config_params
      .where(environment_slug: environment.slug)
      .order(:name)
    )

    begin
      kubernetes_adapter.set_environment_vars(
        vars: env_vars.merge(system_config),
        service: service,
        config_dir: config_dir
      )
    rescue CmdFailedError => e
      Rails.logger.info "set_environment_vars failed: #{e}\nIgnoring"
    end
  end

  def service_is_running?(service:)
    kubernetes_adapter.exists_in_namespace?(
      name: service.slug,
      type: 'service'
    )
  end

  def deployment_exists?(service:)
    kubernetes_adapter.exists_in_namespace?(
      name: service.slug,
      type: 'deployment'
    )
  end

  def delete_pods(service:)
    kubernetes_adapter.delete_pods(
      label: "run=#{service.slug}"
    )
  end

  def delete_deployment(service:)
    kubernetes_adapter.delete_deployment(
      name: kubernetes_adapter.deployment_name(service: service)
    )
  end

  def stop_service(service:)
    if service_is_running?(service: service)
      kubernetes_adapter.delete_service(
        name: service.slug
      )
    end
    if deployment_exists?(service: service)
      delete_deployment(service: service)
    end
  end
end
