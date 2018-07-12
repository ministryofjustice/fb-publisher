require 'net/http'

class ApplicationJob < ActiveJob::Base
  # recommended in https://github.com/resque/resque#activejob
  before_perform do |job|
    ActiveRecord::Base.clear_active_connections!
  end
  # # any errors not handled in other ways will
  # # result in a Non-Retryable failure
  discard_on StandardError do |job, error|
    job.on_non_retryable_exception(error)
  end

  rescue_from Net::OpenTimeout, ActiveRecord::RecordNotFound do |error|
    on_retryable_exception(error)
  end

  def temp_dir
    @temp_dir ||= Dir.mktmpdir
  end

  # override on subclasses as required
  def on_retryable_exception(error)
    log_error(error)
    if executions < 5
      retry_job wait: 10.seconds
    end
  end

  def on_non_retryable_exception(error)
    log_error(error)
  end

  def log_error(error)
    logger.error(error.class.name)
    logger.info(["message: ", error.message].join(' ')) if error.respond_to?(:message)
    logger.info(["backtrace: ", error.backtrace.join("\n")].join(' ')) if error.respond_to?(:backtrace)
  end
end
