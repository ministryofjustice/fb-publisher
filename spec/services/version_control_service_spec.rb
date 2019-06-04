require 'rails_helper'

describe VersionControlService do
  describe '.current_commit' do
    it 'gets the short commit SHA of the given directory' do
      expect(GitAdapter).to receive(:current_commit_sha).with(dir: '/my/dir', short: true).and_return('123456')
      described_class.current_commit(dir: '/my/dir')
    end

    it 'returns the short commit SHA of the given directory' do
      allow(GitAdapter).to receive(:current_commit_sha).with(dir: '/my/dir', short: true).and_return('123456')
      expect(described_class.current_commit(dir: '/my/dir')).to eq('123456')
    end
  end

  describe '.checkout' do
    before do
      allow(GitAdapter).to receive(:clone_repo)
      allow(GitAdapter).to receive(:checkout)
      allow(described_class).to receive(:current_commit).and_return 'my current commit'
    end

    context 'given a to_dir' do
      it 'clones the given repo to the given dir' do
        expect(GitAdapter).to receive(:clone_repo).with(repo_url: anything, to_dir: '/my/dir', deploy_key: nil)
        described_class.checkout(repo_url: 'myrepourl', to_dir: '/my/dir', deploy_key: nil)
      end

      it 'checks out the given ref in the given dir' do
        expect(GitAdapter).to receive(:checkout).with(ref: 'myref', dir: '/my/dir')
        described_class.checkout(repo_url: 'myrepourl', ref: 'myref', to_dir: '/my/dir', deploy_key: nil)
      end

      it 'gets the current commit in the given dir' do
        expect(described_class).to receive(:current_commit).with(dir: '/my/dir').and_return 'my current commit'
        described_class.checkout(repo_url: 'myrepourl', to_dir: '/my/dir', deploy_key: nil)
      end
    end

    context 'given no to_dir' do
      before do
        allow(described_class).to receive(:tmpdir).and_return('/tmp/dir')
      end

      it 'clones the given repo to a tmpdir' do
        expect(GitAdapter).to receive(:clone_repo).with(repo_url: 'myrepourl', to_dir: '/tmp/dir', deploy_key: nil)
        described_class.checkout(repo_url: 'myrepourl', deploy_key: nil)
      end

      it 'checks out the given ref in the tmpdir' do
        expect(GitAdapter).to receive(:checkout).with(ref: 'myref', dir: '/tmp/dir')
        described_class.checkout(repo_url: 'myrepourl', ref: 'myref', deploy_key: nil)
      end

      it 'gets the current commit in the tmpdir' do
        expect(described_class).to receive(:current_commit).with(dir: '/tmp/dir').and_return 'my current commit'
        described_class.checkout(repo_url: 'myrepourl', deploy_key: nil)
      end
    end

    it 'returns the current commit' do
      expect(described_class.checkout(repo_url: 'myrepourl', deploy_key: nil)).to eq('my current commit')
    end
  end
end
