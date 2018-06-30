class GitService
  def self.clone_repo(repo_url:, to_dir: dir)
    ShellAdapter.exec(git_binary, 'clone', repo_url, to_dir)
  end

  def self.checkout(ref: nil, dir:)
    Dir.chdir(dir) do
      ShellAdapter.exec(git_binary, 'checkout', ref)
    end
  end

  def self.current_commit_sha(dir:, short: true)
    short_arg = (short ? '--short' : '')
    Dir.chdir(dir) do
      ShellAdapter.output_of(git_binary, 'rev-parse', short_arg, 'HEAD')
    end
  end

  private

  def self.git_binary
    @git_binary ||= ShellAdapter.output_of("which git")
  end

end
