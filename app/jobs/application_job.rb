class ApplicationJob < ActiveJob::Base
  def temp_dir
    @tmp_dir ||= Dir.mktmpdir
  end
end
