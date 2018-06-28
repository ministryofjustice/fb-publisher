require 'adapters/shell_adapter'

class LocalDockerService
  def self.build(tag:, json_dir:, runner_image_ref: default_runner_image_ref)
    Dir.cwd(File.join(json_dir, '..')) do
      ShellAdapter.exec(docker_binary,
                        'build',
                        "--build-arg RUNNER_IMAGE=#{runner_image_ref}",
                        "-f #{service_dockerfile_path}",
                        "--tag #{tag}",
                        '.')
    end
  end

  def self.docker_binary
    "$(which docker)"
  end

  private

  def self.default_runner_image_ref
    "aldavidson/fb-sample-runner:latest"
  end

  def self.service_dockerfile_path
    Rails.root.join('docker', 'service', 'Dockerfile')
  end




end
