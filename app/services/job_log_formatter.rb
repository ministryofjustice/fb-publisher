class JobLogFormatter
  def self.format(
    message:,
    job:,
    tag:,
    timestamp: Time.now
  )
    line = {
      timestamp: timestamp.to_i,
      job_class: job.class.name,
      job_id: job.job_id,
      tag: tag,
      message: message
    }.to_json
  end
end
