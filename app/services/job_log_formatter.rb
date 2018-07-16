class JobLogFormatter
  def self.format(
    message:,
    job_class:,
    job_id:,
    tag:,
    timestamp: Time.now
  )
    line = {
      timestamp: timestamp.to_i,
      job_class: job_class,
      job_id: job_id,
      tag: tag,
      message: message
    }.to_json
  end
end
