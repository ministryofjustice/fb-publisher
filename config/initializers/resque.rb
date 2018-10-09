# Establish a connection between Resque and Redis
url = (ENV["REDISCLOUD_URL"] || ENV['REDIS_URL'])

begin
  uri_with_protocol = (ENV['REDIS_PROTOCOL'] || 'redis://') + url.to_s
  uri = URI.parse(uri_with_protocol)
  Resque.redis = Redis.new(
    url: uri_with_protocol,
    password: ENV['REDIS_AUTH_TOKEN']
  )
rescue URI::InvalidURIError
  puts "could not parse a valid Redis URI from #{url} - falling back to file log"
end
