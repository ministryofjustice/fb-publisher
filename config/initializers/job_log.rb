url = ENV["REDISCLOUD_URL"] || ENV['REDIS_URL']
job_log_adapter_class = FileLogAdapter
if url.present?
  begin
    uri = URI.parse(url)
    Rails.configuration.x.job_log_redis = Redis.new(host:uri.host, port:uri.port, password:uri.password)
    job_log_adapter_class = RedisLogAdapter
  rescue URI::InvalidURIError
    puts "could not parse a valid Redis URI from #{url} - falling back to file log"
  end
end

Rails.configuration.x.job_log_adapter = job_log_adapter_class
