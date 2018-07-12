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
      Time.unstub(:now)
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
      Time.unstub(:now)
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
end
