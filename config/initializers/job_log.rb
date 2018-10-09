url = ENV["REDISCLOUD_URL"] || ENV['REDIS_URL']
job_log_adapter_class = FileLogAdapter
if url.present?
  begin
    uri_with_protocol = (ENV['REDIS_PROTOCOL'] || 'redis://') + url.to_s
    uri = URI.parse(uri_with_protocol)
    Rails.configuration.x.job_log_redis = Redis.new(
      url: uri_with_protocol,
      password: ENV['REDIS_AUTH_TOKEN']
    )
    job_log_adapter_class = RedisLogAdapter
  rescue URI::InvalidURIError
    puts "could not parse a valid Redis URI from #{url} - falling back to file log"
  end
end

Rails.configuration.x.job_log_adapter = job_log_adapter_class
