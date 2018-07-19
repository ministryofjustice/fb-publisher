require 'rails_helper'
require 'support/time_helpers'

describe JobLogService do
  let(:job) { DeployServiceJob.new }
  let(:tag) { 'my-tag' }

  describe '.tag_for' do
    context 'given a job' do
      it 'returns the class & id separated by ":"' do
        expect(described_class.tag_for(job)).to eq("DeployServiceJob:#{job.job_id}")
      end
    end
  end

  describe '.entries' do
    let(:adapter) { described_class.send(:adapter) }
    let(:adapter_entries) { ['adapter', 'entries'] }
    let(:min_timestamp) { 1.day.ago.to_i }
    before do
      allow(adapter).to receive(:entries).and_return(adapter_entries)
    end

    context 'when there is no tag or job_id' do
      it 'raises an ArgumentError' do
        expect { described_class.entries(min_timestamp: min_timestamp) }.to raise_error(ArgumentError)
      end
    end

    context 'given a tag' do
      it 'calls entries on the adapter, passing all arguments along' do
        expect(adapter).to receive(:entries).with(hash_including(tag: tag))
        described_class.entries(tag: tag)
      end

      it 'returns the result of adapter.entries' do
        expect( described_class.entries(tag: tag) ).to eq(adapter_entries)
      end
    end
  end

  describe '.log_name' do
    context 'given a job and a tag' do
      it 'returns (job_class)_(job_id)_tag_(tag)' do
        expect(described_class.send(:log_name, job: job, tag: tag)).to eq("DeployServiceJob_#{job.job_id}_tag_my-tag")
      end
    end
  end

  describe '.log' do
    before do
      allow(JobLogFormatter).to receive(:format).and_return "formatted message"
      allow(described_class.adapter).to receive(:log)
      allow(described_class).to receive(:log_name).and_return 'my-log-name'
    end
    context 'given a message, tag, and job' do
      let(:message) { 'given message' }
      let!(:now) { Time.current.change(usec: 0) }

      it 'asks JobLogFormatter to format the message with the current timestamp' do
        expect(JobLogFormatter).to receive(:format).with(
          job: job,
          tag: tag,
          message: message,
          timestamp: now
        ).and_return "formatted message"
        travel_to(now) do
          described_class.log( tag: tag, job: job, message: message )
        end
      end

      it 'asks the adapter to log the formatted message, passing the right arguments' do
        expect(described_class.adapter).to receive(:log).with(
          message: 'formatted message',
          job_id: job.job_id,
          tag: tag,
          in_log: 'my-log-name'
        )
        described_class.log( tag: tag, job: job, message: message )
      end
    end
  end
end
