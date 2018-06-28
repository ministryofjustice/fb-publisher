class GitService
  def self.clone_repo(repo_url:, to_dir: dir)
    ShellAdapter.exec(git_binary, 'clone', repo_url, to_dir)
  end

  def self.checkout(ref: nil, dir:)
    Dir.chdir(dir) do
      ShellAdapter.exec(git_binary, 'checkout', ref)
    end
  end

  private

  def self.git_binary
    "$(which git)"
  end

end
