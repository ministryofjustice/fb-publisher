require 'open3'

class ShellAdapter
  # run the given binary with the given arguments,
  # discarding the output
  def self.exec(binary, *args)
    cmd_line = build_cmd( executable: binary, args: args )
    # TODO: maybe use Open3.popen2e instead, so that we
    # can get streaming output as well as exit code?
    result = Kernel.system(cmd_line)
    raise CmdFailedError.new(cause: "#{$?}", message: "failing cmd: #{cmd_line}") unless result
  end

  def self.output_of(*args)
    capture_with_stdin(cmd: args).strip
  end

  def self.capture_with_stdin(cmd: [], stdin: nil)
    cmd_line = build_cmd( executable: cmd[0], args: cmd[1..-1] )

    stdout_str, status = Open3.capture2(cmd_line, stdin_data: stdin)
    unless status.success?
      raise CmdFailedError.new(cause: "#{$?}", message: "failing cmd: #{cmd_line}")
    end
    stdout_str
  end

  def self.build_cmd(executable:, args: [], redirect_to: nil, pipe_to: nil)
    line = [executable, args].flatten.compact.join(' ')
    line = add_pipe(cmd: line, to: pipe_to) if pipe_to.present?
    line = add_redirect(cmd: line, to: redirect_to) if redirect_to.present?
    line
  end

  def self.add_redirect(cmd:, to:, operator: '>>')
    [cmd, operator, to].join(' ')
  end

  def self.add_pipe(cmd:, to:, operator: '|')
    [cmd, operator, to].join(' ')
  end
end
