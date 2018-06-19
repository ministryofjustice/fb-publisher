class ServiceStatusCheck < ActiveRecord::Base
  belongs_to :service

  def url_from_env_and_service
    env = ServiceEnvironment.find(self.environment_slug)
    env.url_for(self.service)
  end

  def net_http_response(timeout: 5)
    begin
      r = Net::HTTP.get(self.url, timeout: timeout)
    rescue SocketError => e
      nil
    end
  end

  def save_response_details!(time_taken:, status:, timestamp: Time.now )
    self.time_taken = time_taken
    self.status = status
    self.timestamp = timestamp
    save!
  end

  def execute!(timeout: 5)
    self.url = url_from_env_and_service

    start = Time.now
    response = net_http_response(timeout: timeout)
    save_response_details!( time_taken: Time.now - start,
                            status: response.try(:code) )

    self
  end

  def parallel_request(timeout: 5)
    self.url = url_from_env_and_service

    req = Typhoeus::Request.new(self.url, headers: {env_slug: environment_slug}, timeout: timeout)
    req.on_complete do |response|
      code = response.response_code == 0 ? nil : response.response_code
      save_response_details!(time_taken: response.total_time, status: code)
      # so that we can return the saved checks,
      # we have to stash them on the response
      # as it's the only way to pass context back out with this
      # execution pattern.
      # The options hash seems like the least-worst place to stash them
      response.options[:saved_check] = self
    end
    req
  end

  def self.execute!(service:, environment_slug:, timeout: 5)
    check = new(  service: service,
                  environment_slug: environment_slug)
    check.execute!(timeout: timeout)
  end

  def self.execute_many!( service:,
                          environment_slugs: ServiceEnvironment.all_keys,
                          timeout: 5)
    hydra = Typhoeus::Hydra.new
    requests = environment_slugs.map do |slug|
      check = new(service: service, environment_slug: slug)
      req = check.parallel_request(timeout: timeout)
      hydra.queue(req)
      req
    end
    # 'run' blocks until all requests are completed
    hydra.run
    requests.map do |request|
      request.response.options[:saved_check]
    end
  end
end
