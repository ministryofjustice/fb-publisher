require 'rails_helper'

describe JobLogFormatter do
  describe '.format' do
    describe 'return value' do
      let(:job) { DeployServiceJob.new }
      let(:timestamp) { Time.now }
      let(:return_value) do
        described_class.format(
          message: 'my message',
          job: job,
          tag: 'my-tag',
          timestamp: timestamp
        )
      end

      it 'is a hash serialised to JSON' do
        expect(JSON.parse(return_value)).to eq(
          {
            'timestamp' => timestamp.to_i,
            'tag' => 'my-tag',
            'message' => 'my message',
            'job_class' => 'DeployServiceJob',
            'job_id' => job.job_id
          }
        )

      end
    end
  end
end
