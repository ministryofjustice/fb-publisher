class StatusService
  def self.service_status(service, environments: ServiceEnvironment.all_keys)
    environments.map do |env_slug|
      last_status(service: service, environment_slug: env_slug) || \
        ServiceStatusCheck.new(
          environment_slug: env_slug,
          url: url_from_env_and_service
        )
    end
  end

  # TODO: implement properly when we have services running
  def self.last_status(service:, environment_slug:)
    ServiceStatusCheck.where( service_id: service.id,
                              environment_slug: environment_slug)
                      .order('timestamp desc')
                      .first
  end

  def self.check(service:, environment:, timeout: 5)
    ServiceStatusCheck.execute!(
      environment_slug: environment.slug,
      service: service,
      timeout: timeout
    )
  end

  def self.check_in_parallel( service:,
                              environments: ServiceEnvironment.all_keys,
                              timeout: 5)
    ServiceStatusCheck.execute_many!(
      service: service,
      environment_slugs: environments,
      timeout: timeout
    )

  end
end
