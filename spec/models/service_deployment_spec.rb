require 'rails_helper'

describe ServiceDeployment do
  describe '#update_status' do
    it 'updates attributes with the status value for the given key' do
      expect(subject).to receive(:update_attributes).with(status: 'completed')
      subject.update_status(:completed)
    end
  end

  describe '#complete!' do
    let(:now) { Time.now }
    before do
      allow(Time).to receive(:now).and_return(now)
    end
    after do
      allow(Time).to receive(:now).and_call_original
    end
    it 'updates attributes with status completed and completed_at now' do
      expect(subject).to receive(:update_attributes).with(
        status: 'completed',
        completed_at: now
      )
      subject.complete!
    end
  end

  describe '#fail!' do
    let(:now) { Time.now }
    before do
      allow(Time).to receive(:now).and_return(now)
    end
    after do
      allow(Time).to receive(:now).and_call_original
    end

    it 'updates attributes with completed_at now' do
      expect(subject).to receive(:update_attributes).with(
        hash_including(completed_at: now)
      )
      subject.fail!
    end

    context 'given retryable true' do
      it 'updates attributes with status failed_retryable' do
        expect(subject).to receive(:update_attributes).with(
          hash_including(status: 'failed_retryable')
        )
        subject.fail!(retryable: true)
      end
    end

    context 'given retryable false' do
      it 'updates attributes with status failed_non_retryable' do
        expect(subject).to receive(:update_attributes).with(
          hash_including(status: 'failed_non_retryable')
        )
        subject.fail!(retryable: false)
      end
    end
  end

  describe '#generate_commit_link' do
    context 'given a service' do
      let(:user) do
        User.create(id: 'abc123', name: 'test user', email: 'test@example.justice.gov.uk')
      end

      let(:service) do
        Service.create!(id: 'fed456',
                        name: 'My New Service',
                        slug: 'my-new-service',
                        git_repo_url: 'https://github.com/some-organisation/some-repository.git',
                        created_by_user: user)
      end

      before do
        subject.update_attributes(service: service, commit_sha: 'a123e56')
      end

      context 'when the git_repo_url exists' do
        it 'sets the Github link for the commit sha' do
          expect(subject.generate_github_link).to eq('https://github.com/some-organisation/some-repository/commit/a123e56')
        end
      end

      context 'when the git_repo_url does not exist' do
        before do
          service.git_repo_url = ''
        end

        it 'does not create a link for the commit sha' do
          expect(subject.generate_github_link).to eq(nil)
        end
      end
    end
  end
end
