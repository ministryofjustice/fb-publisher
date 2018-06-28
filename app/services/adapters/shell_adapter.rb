class ShellAdapter
  def self.exec(binary, *args=[])
    cmd_line = build_cmd( executable: binary, args: args )
    %x[#{cmd_line}}]
  end

  def self.build_cmd(executable:, args: [], redirect_to: nil, pipe_to: nil)
    line = [executable, args].flatten.compact.join(' ')
    line = add_redirect(line, redirect_to) if redirect_to.present?
    line = add_pipe(line, pipe_to) if pipe_to.present?
    line
  end

  def self.add_redirect(cmd:, to:, operator: '>>')
    [cmd, operator, to].join(' ')
  end

  def self.add_pipe(cmd:, to:, operator: '|')
    [cmd, operator, to].join(' ')
  end
end
