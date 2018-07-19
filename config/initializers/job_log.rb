url = ENV["REDISCLOUD_URL"] || ENV['REDIS_URL']
if url.present?
  begin
    uri = URI.parse(url)
    job_log_adapter = RedisLogAdapter
    Rails.configuration.x.job_log_redis = Redis.new(host:uri.host, port:uri.port, password:uri.password)
    Rails.configuration.x.job_log_adapter = job_log_adapter
  rescue URI::InvalidURIError
    puts "could not parse a valid Redis URI from #{url} - falling back to file log"
  end
end

Rails.configuration.x.job_log_adapter ||= FileLogAdapter
