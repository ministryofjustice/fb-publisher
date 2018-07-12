require 'rails_helper'

describe GitAdapter do
  before do
    allow(ShellAdapter).to receive(:exec)
    allow(ShellAdapter).to receive(:output_of).and_return('cmd output')
    allow(ShellAdapter).to receive(:output_of).with("which git").and_return('git')
  end

  describe '.clone_repo' do
    it 'execs a git clone of the given repo_url to the given dir' do
      expect(ShellAdapter).to receive(:exec).with('git', 'clone', '/repo/url', '/target/dir')
      described_class.clone_repo(repo_url: '/repo/url', to_dir: '/target/dir')
    end
  end

  describe '.checkout' do
    before do
      allow(Dir).to receive(:chdir).and_yield
    end

    it 'changes directory to the given dir' do
      allow(Dir).to receive(:chdir).with(dir: '/my/dir')
      described_class.checkout(dir: '/my/dir')
    end

    it 'checks out the given ref' do
      expect(ShellAdapter).to receive(:exec).with('git', 'checkout', 'myref')
      described_class.checkout(dir: '/my/dir', ref: 'myref')
    end
  end

  describe '.current_commit_sha' do
    before do
      allow(Dir).to receive(:chdir).and_yield
    end

    it 'changes directory to the given dir' do
      allow(Dir).to receive(:chdir).with(dir: '/my/dir')
      described_class.current_commit_sha(dir: '/my/dir')
    end

    it 'gets the output of git rev-parse' do
      expect(ShellAdapter).to receive(:output_of).with('git', 'rev-parse', anything, 'HEAD')
      described_class.current_commit_sha(dir: '/my/dir')
    end

    it 'returns the output of git rev-parse' do
      expect( described_class.current_commit_sha(dir: '/my/dir') ).to eq('cmd output')
    end
  end
end
