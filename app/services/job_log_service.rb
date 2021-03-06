class JobLogService
  def self.log(message:, job:, tag: nil)
    formatted_message = JobLogFormatter.format(
      message: message,
      job: job,
      tag: tag,
      timestamp: Time.current
    )
    adapter.log(
      message: formatted_message,
      job_id: job.job_id,
      in_log: log_name(job: job, tag: tag),
      tag: tag
    )
  end

  def self.entries(tag: nil, job_id: nil, min_timestamp: nil)
    raise ArgumentError.new("You must supply at least one of tag: or job_id:") if tag.nil? && job_id.nil?
    adapter.entries(job_id: job_id, tag: tag, min_timestamp: min_timestamp)
  end

  def self.tag_for(job)
    [job.class.name, job.job_id].join(':')
  end

  private

  def self.adapter
    Rails.configuration.x.job_log_adapter
  end

  def self.log_name(job:, tag:)
    [job.class.name, job.job_id, 'tag', tag].join('_')
  end
end
