require 'rails_helper'

describe DeployServiceJob do
  let(:json_sub_dir) { nil }
  let(:service) { double('service', git_repo_url: 'git://some/repo') }
  let(:deployment) do
    double('deployment',
      id: 'my-deployment-id',
      commit_sha: 'tag:1234',
      json_sub_dir: json_sub_dir,
      service: service,
      environment_slug: 'myenv'
    )
  end

  before do
    allow(ServiceDeployment).to receive(:find).with('my-deployment-id').and_return(deployment)
    allow(deployment).to receive(:update_status)
    allow(deployment).to receive(:update_attributes)
    allow(deployment).to receive(:complete!)
    allow(VersionControlService).to receive(:checkout).and_return('some-sha')
    allow(DeploymentService).to receive(:build).and_return('build-result')
    allow(DeploymentService).to receive(:push).and_return('push-result')
    allow(DeploymentService).to receive(:restart).and_return('restart-result')
    allow(DeploymentService).to receive(:configure).and_return('configure-result')
  end

  describe '#perform' do
    let(:perform) do
      subject.perform(service_deployment_id: deployment.id)
    end

    let(:perform_and_handle_error) do
      begin
        described_class.perform_now(service_deployment_id: deployment.id)

      rescue CmdFailedError => e
        Rails.logger.info "expected error -- #{e.message}"
      end
    end

    it 'loads the deployment' do
      expect(ServiceDeployment).to receive(:find).with('my-deployment-id').and_return(deployment)
      perform
    end

    describe 'starting' do
      it 'updates the status of the deployment to :running' do
        expect(deployment).to receive(:update_status).with(:running)
        perform
      end
    end

    context 'when the job throws a retryable error' do
      before do
        allow(DeploymentService).to receive(:build).and_raise(Net::OpenTimeout.new("expected exception"))
        allow(deployment).to receive(:fail!)
      end

      it 'does not complete! the deployment' do
        expect(deployment).to_not receive(:complete!)
        perform_and_handle_error
      end

      it 'logs the error' do
        expect_any_instance_of(described_class).to receive(:log_error)
        perform_and_handle_error
      end

      it 'fail!s the deployment passing true for retryable' do
        expect(deployment).to receive(:fail!).with(true)
        perform_and_handle_error
      end
    end

    context 'when the job throws a non-retryable error' do
      before do
        allow(DeploymentService).to receive(:build).and_raise(CmdFailedError.new("expected exception"))
        allow(deployment).to receive(:fail!)
      end

      it 'does not complete! the deployment' do
        expect(deployment).to_not receive(:complete!)
        perform_and_handle_error
      end

      it 'logs the error' do
        expect_any_instance_of(described_class).to receive(:log_error)
        perform_and_handle_error
      end

      it 'fail!s the deployment passing false for retryable' do
        expect(deployment).to receive(:fail!).with(false)
        perform_and_handle_error
      end
    end

    context 'when the job does not throw an error' do
      it 'complete!s the deployment' do
        expect(deployment).to receive(:complete!)
        perform
      end
    end

    it 'checks out the code from the VersionControlService' do
      expect(VersionControlService).to receive(:checkout).with(
        repo_url: service.git_repo_url,
        ref: deployment.commit_sha,
        to_dir: anything
      ).and_return('some-sha')
      perform
    end

    it 'updates the deployment with the returned commit sha' do
      expect(deployment).to receive(:update_attributes).with(commit_sha: 'some-sha')
      perform
    end
  end
end
