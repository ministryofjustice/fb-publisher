require 'rails_helper'

describe DeployServiceJob do
  let(:json_sub_dir) { nil }
  let(:service) { double('service', git_repo_url: 'https://some/repo', deploy_key: nil) }
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
    allow(JobLogService).to receive(:log)
    allow(ServiceDeployment).to receive(:find).with('my-deployment-id').and_return(deployment)
    allow(deployment).to receive(:update_status)
    allow(deployment).to receive(:update_attributes)
    allow(deployment).to receive(:complete!)
    allow(VersionControlService).to receive(:checkout).and_return('some-sha')
    allow(DeploymentService).to receive(:setup_service).and_return('setup_service-result')
    allow(DeploymentService).to receive(:expose).and_return('expose-result')
    allow(DeploymentService).to receive(:create_network_policy)
    allow(DeploymentService).to receive(:configure_env_vars).and_return('configure_env_vars-result')
    allow(DeploymentService).to receive(:restart_service).and_return('restart_service-result')
    allow(DeploymentService).to receive(:create_service_token_secret).and_return('create_service_token_secret-result')
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

    it 'calls create_network_policy' do
      expect(DeploymentService).to receive(:create_network_policy)
      perform
    end

    it 'loads the deployment' do
      expect(ServiceDeployment).to receive(:find).with('my-deployment-id').and_return(deployment)
      perform
    end

    describe 'starting' do
      it 'updates the status of the deployment to :deploying' do
        expect(deployment).to receive(:update_status).with(:deploying)
        perform
      end
    end

    context 'when the job throws a retryable error' do
      before do
        allow(DeploymentService).to receive(:setup_service).and_raise(Net::OpenTimeout.new("expected exception"))
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
        expect(deployment).to receive(:fail!).with(retryable: true)
        perform_and_handle_error
      end
    end

    context 'when the job throws a non-retryable error' do
      before do
        allow(DeploymentService).to receive(:setup_service).and_raise(CmdFailedError.new("expected exception"))
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
        expect(deployment).to receive(:fail!).with(retryable: false)
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
        deploy_key: nil
      ).and_return('some-sha')
      perform
    end

    it 'updates the deployment with the returned commit sha' do
      expect(deployment).to receive(:update_attributes).with(commit_sha: 'some-sha')
      perform
    end

    it 'restarts the service' do
      expect(DeploymentService).to receive(:restart_service).with(
        service: service,
        environment_slug: 'myenv'
      )
      perform
    end
  end
end
