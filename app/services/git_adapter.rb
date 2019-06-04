require 'fileutils'

class GitAdapter
  # TODO: this is not thread/process safe and does not scale
  def self.clone_repo(repo_url:, deploy_key:, to_dir: dir)
    if deploy_key.present?
      FileUtils.mkdir "#{ENV['HOME']}/.ssh"
      File.open("#{ENV['HOME']}/.ssh/deploy_key", 'w') do |f|
        f.write deploy_key
      end
      FileUtils.chmod 0600, "#{ENV['HOME']}/.ssh/deploy_key"
      Kernel.system('ssh-keyscan -H github.com > ~/.ssh/known_hosts')

      variables = { 'GIT_SSH_COMMAND' => 'ssh -i ~/.ssh/deploy_key' }
      BetterShellAdapter.exec(git_binary, variables, 'clone', repo_url, to_dir)
    else
      ShellAdapter.exec(git_binary, 'clone', repo_url, to_dir)
    end
  end

  def self.checkout(ref: nil, dir:)
    Dir.chdir(dir) do
      ShellAdapter.exec(git_binary, 'checkout', ref.to_s)
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
