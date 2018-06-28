class ApplicationJob < ActiveJob::Base
  def temp_dir
    @tmp_dir ||= Dir.tmpdir
  end
end
