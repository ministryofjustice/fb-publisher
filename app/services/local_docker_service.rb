class LocalDockerService
  def self.build(tag:, json_dir:, runner_image_ref: default_runner_image_ref)
    Dir.chdir(File.join(json_dir, '..')) do
      ShellAdapter.exec(docker_binary,
                        'build',
                        "--build-arg RUNNER_IMAGE=#{runner_image_ref}",
                        "--build-arg JSON_DIR=$(basename #{json_dir})",
                        "-f #{service_dockerfile_path}",
                        "--tag #{tag}",
                        '.')
    end
  end

  def self.push_to_dockerhub(repository_scope:, tag:)
    scoped_tag = tag

    unless tag.starts_with?(repository_scope + '/')
      scoped_tag = [repository_scope, tag].join('/')
      ShellAdapter.exec(
        self.docker_binary,
        'tag',
        tag,
      )
    end

    login

    ShellAdapter.exec(
      self.docker_binary,
      'push',
      scoped_tag
    )
  end

  #
  def self.login(
    host: ENV['REMOTE_DOCKER_HOST'],
    username: ENV['REMOTE_DOCKER_USERNAME'],
    password: ENV['REMOTE_DOCKER_PASSWORD']
  )
    # pass username & password only through env vars so that
    # the values don't go in history or logs
    ShellAdapter.capture_with_stdin(
      stdin: password,
      cmd: [
        self.docker_binary,
        'login',
        '-u',
        username,
        '--password-stdin',
        host.to_s
      ]
    )
  end

  private

  def self.docker_binary
    "$(which docker)"
  end

  def self.default_runner_image_ref
    # old c100 prototype runner
    # "aldavidson/fb-sample-runner:latest"

    # shiny new general-purpose runner:
    "aldavidson/fb-runner-node:latest"
  end

  def self.service_dockerfile_path
    Rails.root.join('docker', 'service', 'Dockerfile')
  end




end
