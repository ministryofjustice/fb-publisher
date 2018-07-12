class UpdateDeploymentStatusNames < ActiveRecord::Migration[5.2]
  def change
    ServiceDeployment.where(status: 'running').update_all(status: 'deploying')
    ServiceDeployment.where(status: 'scheduled').update_all(status: 'queued')
  end
end
