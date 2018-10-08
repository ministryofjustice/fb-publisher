url = ENV["REDISCLOUD_URL"] || ENV['REDIS_URL']
if url.present?
  begin
    uri_with_protocol = (ENV['REDIS_PROTOCOL'] || 'redis://') + url
    uri = URI.parse(uri_with_protocol)
    $redis = Redis.new(
      url: uri_with_protocol,
      password: ENV['REDIS_AUTH_TOKEN']
    )
  rescue URI::InvalidURIError
    puts "could not parse a valid Redis URI from #{url} - falling back to file log"
  end
end
