class ResourcingService
  attr_reader :service, :environment_slug

  def initialize(service:, environment_slug:)
    @service = service
    @environment_slug = environment_slug
  end

  def limits_cpu
    config_param = service.service_config_params
                          .where(name: 'RESOURCES_LIMITS_CPU')
                          .where(environment_slug: environment_slug)
                          .first

    param = config_param || ServiceConfigParam.new
    param.value || default_resources.dig(:limits, :cpu)
  end

  def limits_memory
    config_param = service.service_config_params
                          .where(name: 'RESOURCES_LIMITS_MEMORY')
                          .where(environment_slug: environment_slug)
                          .first

    param = config_param || ServiceConfigParam.new
    param.value || default_resources.dig(:limits, :memory)
  end

  def requests_cpu
    config_param = service.service_config_params
                          .where(name: 'RESOURCES_REQUESTS_CPU')
                          .where(environment_slug: environment_slug)
                          .first

    param = config_param || ServiceConfigParam.new
    param.value || default_resources.dig(:requests, :cpu)
  end

  def requests_memory
    config_param = service.service_config_params
                          .where(name: 'RESOURCES_REQUESTS_MEMORY')
                          .where(environment_slug: environment_slug)
                          .first

    param = config_param || ServiceConfigParam.new
    param.value || default_resources.dig(:requests, :memory)
  end

  def deployment_replicas
    config_param = service.service_config_params
                          .where(name: 'DEPLOYMENT_REPLICAS')
                          .where(environment_slug: environment_slug)
                          .first

    param = config_param || ServiceConfigParam.new
    param.value || default_deployment_replicas
  end

  private

  def default_deployment_replicas
    4
  end

  def default_resources
    {
      limits: {
        cpu: '150m',
        memory: '300Mi',
      },
      requests: {
        cpu: '10m',
        memory: '128Mi'
      }
    }.freeze
  end
end
