class StatusService
  def self.service_status(service, environments: ServiceEnvironment.all_keys)
    environments.map do |env|
      service_environment_status(service: service, environment: ServiceEnvironment.find(env))
    end
  end

  def self.service_environment_status(service:, environment:)
    last_check = last_status(service: service, environment: environment)
    {
      environment: {
        slug: environment.slug,
        name: environment.name
      },
      service: {
        url: environment.url_for(service),
        status: last_check[:status],
        checked_at: last_check[:timestamp]
      }
    }
  end

  # TODO: implement properly when we have services running
  def self.last_status(service:, environment:)
    {
      status: nil,
      timestamp: nil
    }
  end

  def self.check(service:, environment:)
    r = Net::HTTP.get_response(URI.parse(environment.url_for(service)))
    {
      status: r.code,
      timestamp: Time.now
    }
  end
end
