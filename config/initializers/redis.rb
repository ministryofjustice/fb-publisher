if url = (ENV["REDISCLOUD_URL"] || ENV["REDIS_URL"])
  $redis = Redis.new(:url => url)
end
