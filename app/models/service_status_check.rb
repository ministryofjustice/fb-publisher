class ServiceStatusCheck < ActiveRecord::Base
  belongs_to :service

  def self.execute!(service:, environment:, timeout: 5)
    url = environment.url_for(service)
    start = Time.now

    response = begin
      r = Net::HTTP.get(URI.parse(url), timeout: timeout)
    rescue SocketError => e
      nil
    end
    time_taken = Time.now - start

    create!(
      {
        environment_slug: environment.slug,
        service: service,
        status: response.try(:code),
        timestamp: Time.now,
        time_taken: time_taken,
        url: url
      }
    )
  end

  def self.execute_many!( service:,
                          environment_slugs: ServiceEnvironment.all_keys,
                          timeout: 5)
    results = []
    hydra = Typhoeus::Hydra.new
    environment_slugs.map do |slug|
      env = ServiceEnvironment.find(slug)
      req = Typhoeus::Request.new(env.url_for(service), timeout: timeout)
      req.on_complete do |response|
        code = response.response_code == 0 ? nil : response.response_code
        results << create!({
          environment_slug: env.slug,
          service: service,
          status: code,
          timestamp: Time.now,
          time_taken: response.total_time,
          url: req.url
        })
      end
      hydra.queue(req)
    end
    # blocks until all completed
    hydra.run
    results
  end
end
