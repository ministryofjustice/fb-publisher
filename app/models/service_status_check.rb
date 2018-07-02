class ServiceStatusCheck < ActiveRecord::Base
  belongs_to :service

  validates :environment_slug, inclusion: {in: ServiceEnvironment.all_slugs.map(&:to_s)}

  def url_from_env_and_service
    DeploymentService.url_for(service: self.service, environment_slug: self.environment_slug)
    # env = ServiceEnvironment.find(self.environment_slug)
    # env.url_for(self.service)
  end

  def execute!(timeout: 5)
    self.url = url_from_env_and_service
    start = Time.now
    response = net_http_response(timeout: timeout)
    save_response_details!( time_taken: Time.now - start,
                            status: response.try(:code) )

    self
  end

  def self.execute!(service:, environment_slug:, timeout: 5)
    check = new(  service: service,
                  environment_slug: environment_slug)
    check.execute!(timeout: timeout)
  end

  def self.execute_many!( service:,
                          environment_slugs: ServiceEnvironment.all_slugs,
                          timeout: 5)
    requests = parallel_requests( service: service,
                                  environment_slugs: environment_slugs,
                                  timeout: timeout )
    hydra = Typhoeus::Hydra.new
    requests.each { |r| hydra.queue(r) }
    # 'run' blocks until all requests are completed
    hydra.run
    requests.map do |request|
      request.response.options[:saved_check]
    end
  end

  def self.latest(service_id:, environment_slug:)
    where(  service_id: service_id,
            environment_slug: environment_slug)
    .order('timestamp desc')
    .first
  end


  def net_http_response(timeout: 5)
    begin
      uri = URI.parse(self.url)
      # minikube doesn't put the / on the end of urls
      uri.path = '/' if uri.path.blank?
      http = setup_http_object(uri: uri, timeout: timeout)
      resp = http.start() do |http|
        http.get(uri.path)
      end
    rescue SocketError, Net::OpenTimeout => e
      nil
    end
  end
  private

  def setup_http_object(uri:, timeout: 5)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')
    http.read_timeout = timeout
    http.open_timeout = timeout
    http
  end

  def save_response_details!(time_taken:, status:, timestamp: Time.now )
    self.time_taken = time_taken
    self.status = status
    self.timestamp = timestamp
    save!
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

  def self.parallel_requests( service: service,
                              environment_slugs: environment_slugs,
                              timeout: timeout )
    environment_slugs.map do |slug|
      check = new(service: service, environment_slug: slug)
      check.send(:parallel_request, timeout: timeout)
    end
  end
end
