# Establish a connection between Resque and Redis
redis_url = (ENV["REDISCLOUD_URL"] || ENV['REDIS_URL'])
if redis_url && (Rails.env.production? || Rails.env.staging?)
  uri = URI.parse redis_url
  Resque.redis = Redis.new host:uri.host, port:uri.port, password:uri.password
else
  # conf for your localhost
end
