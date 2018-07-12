class VersionControlService
  # Clones repo, checks out the given ref to the given dir,
  # and returns the current commit id of that ref
  def self.checkout(repo_url:, ref: nil, to_dir: tmpdir)
    GitAdapter.clone_repo(repo_url: repo_url, to_dir: to_dir)
    GitAdapter.checkout(ref: ref, dir: to_dir)
    current_commit(dir: to_dir)
  end

  def self.current_commit(dir:)
    GitAdapter.current_commit_sha(dir: dir, short: true)
  end

  private

  def self.tmpdir
    Dir.mktmpdir
  end
end
