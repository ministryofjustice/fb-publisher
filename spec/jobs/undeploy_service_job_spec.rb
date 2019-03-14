require 'rails_helper'

describe UndeployServiceJob do
  let(:json_sub_dir) { nil }
  let(:service) { double('service', git_repo_url: 'https://some/repo', slug: 'some-slug') }
  let(:deployment) do
    double('deployment',
           id: 'my-deployment-id',
           commit_sha: 'tag:5678',
           json_sub_dir: json_sub_dir,
           service: service,
           environment_slug: 'mydev',
           status: 'completed'
    )
  end

  before do
    allow(JobLogService).to receive(:log)
    allow(ServiceDeployment).to receive(:find).with('my-deployment-id').and_return(deployment)
    allow(DeploymentService).to receive(:stop_service).and_return('stop_service-result')
    allow(deployment).to receive(:destroy)
  end

  describe 'perform' do
    let(:perform_and_handle_error) do
      begin
        described_class.perform_now(service_deployment_id: deployment.id)

      rescue CmdFailedError => e
        Rails.logger.info "expected error -- #{e.message}"
      end
    end

    context 'when the job does not throw an error' do
      it 'removes the deployment' do
        expect(ServiceDeployment).to receive(:find).with('my-deployment-id').and_return(deployment)
        expect(deployment).to receive(:destroy)
        subject.perform(service_deployment_id: deployment.id)
      end
    end

    context 'when the job throws a retryable error' do
      before do
        allow(DeploymentService).to receive(:stop_service).and_raise(Net::OpenTimeout.new("expected exception"))
        allow(deployment).to receive(:fail!)
      end

      it 'does not remove the deployment' do
        expect(deployment).to_not receive(:destroy)
        perform_and_handle_error
      end

      it 'logs the error' do
        expect_any_instance_of(described_class).to receive(:log_error)
        perform_and_handle_error
      end

      it 'fail!s the un-deployment passing true for retryable' do
        expect(deployment).to receive(:fail!).with(retryable: true)
        perform_and_handle_error
      end
    end

    context 'when the job throws a non-retryable error' do
      before do
        allow(DeploymentService).to receive(:stop_service).and_raise(CmdFailedError.new("expected exception"))
        allow(deployment).to receive(:fail!)
      end

      it 'does not remove! the deployment' do
        expect(deployment).to_not receive(:destroy)
        perform_and_handle_error
      end

      it 'logs the error' do
        expect_any_instance_of(described_class).to receive(:log_error)
        perform_and_handle_error
      end

      it 'fail!s the deployment passing false for retryable' do
        expect(deployment).to receive(:fail!).with(retryable: false)
        perform_and_handle_error
      end
    end
  end
end
