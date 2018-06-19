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
    nil
  end

  def self.check(service:, environment:)
    url = environment.url_for(service)
    start = Time.now

    response = begin
      r = Net::HTTP.get(URI.parse(url))
    rescue SocketError => e
      nil
    end
    time_taken = Time.now - start

    {
      environment: environment.slug,
      service: service.slug,
      status: response.try(:code),
      timestamp: Time.now,
      time_taken: time_taken,
      url: url
    }
  end

  def self.check_in_parallel( service:,
                              environments: ServiceEnvironment.all_keys,
                              timeout: 5)
    hydra = Typhoeus::Hydra.new
    requests = environments.map do |env|
      env = ServiceEnvironment.find(env)
      req = Typhoeus::Request.new(env.url_for(service), timeout: timeout)
      hydra.queue(req)
      req
    end
    # blocks until all completed
    hydra.run
    index = 0
    checks = requests.map do |request|
      resp = request.response
      code = resp.response_code == 0 ? nil : resp.response_code
      {
        environment: environments[index],
        service: service.slug,
        status: code,
        timestamp: Time.now,
        time_taken: resp.total_time,
        url: request.url
      }
    end
  end
end
