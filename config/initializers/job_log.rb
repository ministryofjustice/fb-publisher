
if ['production', 'staging'].include?(ENV['RAILS_ENV'])
  job_log_adapter = RedisLogAdapter
  uri = uri = URI.parse (ENV["REDISCLOUD_URL"] || ENV['REDIS_URL'])
  job_log_adapter.redis = Redis.new(host:uri.host, port:uri.port, password:uri.password)
else
  job_log_adapter = FileLogAdapter
end

Rails.configuration.x.job_log_adapter = job_log_adapter
