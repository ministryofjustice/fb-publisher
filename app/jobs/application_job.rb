class ApplicationJob < ActiveJob::Base
  def temp_dir
    @temp_dir ||= Dir.mktmpdir
  end
end
