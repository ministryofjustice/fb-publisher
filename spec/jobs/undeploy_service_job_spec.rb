require 'rails_helper'

describe UndeployServiceJob, type: :job do
  include ActiveJob::TestHelper

  subject(:un_deploy_job) { described_class.perform_later(env: 'mydev', service_slug: 'some-slug') }

  it 'queues the job' do
    expect { un_deploy_job }.to change(ActiveJob::Base.queue_adapter.enqueued_jobs, :size).by(1)
  end

  it 'is in default queue' do
    expect(UndeployServiceJob.new.queue_name).to eq('default')
  end

  it 'executes perform' do
    expect(DeploymentService).to receive(:stop_service_by_slug).with(environment_slug: :mydev, slug: 'some-slug')
    perform_enqueued_jobs { un_deploy_job }
  end

  context 'when the job throws a retryable error' do
    it 'handles no results error' do
      allow(DeploymentService).to receive(:stop_service_by_slug).and_raise(Net::OpenTimeout.new("expected exception"))

      perform_enqueued_jobs do
        expect_any_instance_of(UndeployServiceJob).to receive(:retry_job).with(wait: 10.seconds)

        un_deploy_job
      end
    end
  end

  context 'when something unexpected happens' do
    let(:perform_and_handle_error) do
      begin
        described_class.perform_now(env: 'mydev', service_slug: 'some-slug')

      rescue CmdFailedError => e
        Rails.logger.info "expected error -- #{e.message}"
      end
    end

    it 'does something I do not understand' do
      allow(DeploymentService).to receive(:stop_service_by_slug).and_raise(CmdFailedError.new("expected exception"))
      perform_enqueued_jobs do
        perform_and_handle_error
        expect_any_instance_of(UndeployServiceJob).not_to receive(:retry_job)

        un_deploy_job
      end
    end
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end
end
