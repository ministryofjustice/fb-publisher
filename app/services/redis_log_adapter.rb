class RedisLogAdapter
  def self.log(message:, job_id:, tag:, in_log:)
    byebug
    connection.append(
      key_for(job_id: job_id, tag: tag),
      message + "\n"
    )
  end

  def self.entries(job_id: nil, tag: nil, min_timestamp: nil)
    entries = []
    keys_matching(job_id: job_id, tag: tag, min_timestamp: min_timestamp).each do |key|
      entries += all_entries_in_log_matching(
        key: key,
        job_id: job_id,
        tag: tag,
        min_timestamp: min_timestamp
      )
    end

    entries.compact.flatten.sort_by { |e| e['timestamp'] }
  end

  def self.all_entries_in_log(log: nil, key: nil)
    key ||= log
    entries = connection.get(key).split("\n").map {|line| JSON.parse(line)  rescue nil}
  end

  def self.all_entries_in_log_matching(log: nil, key: nil, job_id: nil, tag: nil, min_timestamp: nil)
    all_entries_in_log(log: log, key: key).select do |obj|
      entry_matches?(entry: obj, job_id: job_id, tag: tag, min_timestamp: min_timestamp)
    end
  end

  def self.purge_logs(max_timestamp:)
    keys_matching(max_timestamp: max_timestamp).each do |f|
      File.delete(f)
    end
  end

  private

  def self.connection
    Rails.configuration.x.job_log_redis
  end

  def self.key_matches?(key:, job_id: nil, tag: nil, min_timestamp: nil, max_timestamp: nil)
    return false unless key
    return false if job_id && key =~ /job_#{job_id}/
    return false if tag && key =~ /tag_#{tag}/
    # Not supported on Redis
    # return false if min_timestamp && File.mtime(key).to_i < min_timestamp
    # return false if max_timestamp && File.mtime(key).to_i > max_timestamp
    true
  end

  def self.keys_matching(job_id: nil, tag: nil, min_timestamp: nil, max_timestamp: nil)
    keys = connection.keys(pattern = "*job_*")
    entries = []
    keys.select do |key|
      key_matches?(key: key, job_id: nil, tag: nil, min_timestamp: nil, max_timestamp: max_timestamp)
    end
  end

  def self.entry_matches?(entry:, job_id: nil, tag: nil, min_timestamp: nil)
    return false unless entry
    return false if job_id && entry['job_id'] != job_id
    return false if tag && entry['tag'] != tag
    return false if min_timestamp && entry['timestamp'] < min_timestamp
    true
  end

  def self.key_for(job_id:, tag:)
    ['job', job_id, 'tag', tag].join('_')
  end

  def self.log_dir
    File.join(Rails.root, 'log', 'jobs')
  end
end
