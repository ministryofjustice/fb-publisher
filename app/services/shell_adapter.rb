require 'open3'

class ShellAdapter
  def self.exec(binary, *args)
    cmd_line = build_cmd( executable: binary, args: args )
    Rails.logger.info "executing cmd #{cmd_line}"
    # TODO: maybe use Open3.popen2e instead, so that we
    # can get streaming output as well as exit code?
    result = Kernel.system(cmd_line)
    raise CmdFailedError.new(cause: "#{$?}", message: "failing cmd: #{cmd_line}") unless result
  end

  # NOTE: concatenates a streaming buffer into one string to return
  # - not scalable to long output!
  def self.output_of(*args)
    output = []
    exit_code = Open3.popen2e(*args) do |stdin, stdout_and_stderr, wait_thread|
      stdout_and_stderr.each_line do |line|
        output << line
      end
      unless wait_thread.value.success?
        build_cmd( executable: binary, args: args )
        raise CmdFailedError.new(cause: "#{$?}", message: "failing cmd: #{cmd_line}")
      end
    end
    output.join('\n').strip
  end

  def self.build_cmd(executable:, args: [], redirect_to: nil, pipe_to: nil)
    line = [executable, args].flatten.compact.join(' ')
    line = add_redirect(cmd: line, to: redirect_to) if redirect_to.present?
    line = add_pipe(cmd: line, to: pipe_to) if pipe_to.present?
    line
  end

  def self.add_redirect(cmd:, to:, operator: '>>')
    [cmd, operator, to].join(' ')
  end

  def self.add_pipe(cmd:, to:, operator: '|')
    [cmd, operator, to].join(' ')
  end
end
