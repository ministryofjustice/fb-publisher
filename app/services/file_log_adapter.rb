class FileLogAdapter
  def self.log(message:, job_id:, tag:, in_log:)
    log = file_path(in_log)
    FileUtils.mkdir_p(log_dir) unless File.exist?(log_dir)
    File.open(log, 'a') do |f|
      f << message + "\n"
    end
  end

  def self.entries(job_id: nil, tag: nil, min_timestamp: nil)
    entries = []
    files_matching(job_id: job_id, tag: tag, min_timestamp: min_timestamp).each do |file|
      entries += all_entries_in_log_matching(
        filename: file,
        job_id: job_id,
        tag: tag,
        min_timestamp: min_timestamp
      )
    end

    entries.compact.flatten.sort_by { |e| e['timestamp'] }
  end

  def self.all_entries_in_log(log: nil, filename: nil)
    filename ||= file_path(log)
    file_entries = File.open(filename, 'r') do |f|
      f.readlines.map {|line| JSON.parse(line)  rescue nil}
    end
  end

  def self.all_entries_in_log_matching(log: nil, filename: nil, job_id: nil, tag: nil, min_timestamp: nil)
    all_entries_in_log(log: log, filename: filename).select do |obj|
      entry_matches?(entry: obj, job_id: job_id, tag: tag, min_timestamp: min_timestamp)
    end
  end

  def self.purge_logs(max_timestamp:)
    files_matching(max_timestamp: max_timestamp).each do |f|
      File.delete(f)
    end
  end

  private

  def self.file_matches?(file:, job_id: nil, tag: nil, min_timestamp: nil, max_timestamp: nil)
    return false unless file
    return false if job_id && file =~ /job_#{job_id}/
    return false if tag && file =~ /tag_#{tag}/
    return false if min_timestamp && File.mtime(file).to_i < min_timestamp
    return false if max_timestamp && File.mtime(file).to_i > max_timestamp
    true
  end

  def self.files_matching(job_id: nil, tag: nil, min_timestamp: nil, max_timestamp: nil)
    files = Dir.glob(log_dir + '/**.txt')
    entries = []
    files.select do |file|
      file_matches?(file: file, job_id: nil, tag: nil, min_timestamp: nil, max_timestamp: max_timestamp)
    end
  end

  def self.entry_matches?(entry:, job_id: nil, tag: nil, min_timestamp: nil)
    return false unless entry
    return false if job_id && entry['job_id'] != job_id
    return false if tag && entry['tag'] != tag
    return false if min_timestamp && entry['timestamp'] < min_timestamp
    true
  end

  def self.file_name(job_id:, tag:)
    ['job', job_id, 'tag', tag].join('_')
  end

  def self.file_path(in_log)
    File.join(log_dir, in_log) + '.txt'
  end

  def self.log_dir
    File.join(Rails.root, 'log', 'jobs')
  end
end
