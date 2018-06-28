require 'adapters/shell_adapter'

class MinikubeAdapter
  def self.import_image(environment_slug:, image:, private_key_path: default_private_key_path)
    cmd = ShellAdapter.build_cmd(
      executable: 'docker',
      args: ['save', image],
      pipe_to: ssh_cmd(cmd_to_run:  'docker load ')
    )
    ShellAdapter.exec(cmd)
  end

  private

  def self.default_private_key_path
    "~/.minikube/machines/minikube/id_rsa"
  end

  def self.ssh_cmd(cmd_to_run: nil, private_key_path: default_private_key_path)
    ShellAdapter.build_cmd(
      executable: 'ssh',
      args: [
        '-o UserKnownHostsFile=/dev/null',
        '-o StrictHostKeyChecking=no',
        '-o LogLevel=quiet',
        '-i #{private_key_path}',
        'docker@$(minikube ip)',
        cmd_to_run
      ]
    )
  end
end
