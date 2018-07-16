
if uri = URI.parse(ENV["REDISCLOUD_URL"] || ENV['REDIS_URL'])
  job_log_adapter = RedisLogAdapter
  Rails.configuration.x.job_log_redis = Redis.new(host:uri.host, port:uri.port, password:uri.password)
  Rails.configuration.x.job_log_adapter = job_log_adapter
else
  Rails.configuration.x.job_log_adapter = FileLogAdapter
end
