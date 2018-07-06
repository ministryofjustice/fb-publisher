class ApplicationJob < ActiveJob::Base
  discard_on NonRetryableException do |job, error|
    job.on_non_retryable_exception(error)
  end

  retry_on RetryableException, wait: :exponentially_longer, attempts: 4 do |job, error|
    job.on_retryable_exception(error)
  end

  rescue_from(::ActiveRecord::RecordNotFound, ::Net::OpenTimeout) do |exception|
    raise RetryableException.new(exception)
  end

  # any errors not handled in other ways will
  # result in a Non-Retryable failure
  rescue_from(StandardError) do |exception|
    raise NonRetryableException.new(exception)
  end

  def temp_dir
    @temp_dir ||= Dir.mktmpdir
  end

  # override on subclasses as required
  def on_retryable_exception(error)
    Logger.error(error.message, backtrace: error.backtrace)
  end

  def on_non_retryable_exception(error)
    Logger.error(error.message, backtrace: error.backtrace)
  end
end
