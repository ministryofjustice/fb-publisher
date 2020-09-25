desc 'Republish all forms. Run: USER=my-email@digital.justice.gov.uk bundle exec rake republish_all_forms'
task republish_all_forms: :environment do
  user = User.find_by(email: ENV.fetch('USER'))
  raise "Can not find user #{ENV.fetch('USER')}" if user.blank?

  Service.find_each do |service|
    # The environment for forms are:
    # test-DEV or test-PRODUCTION / live-DEV or live-PRODUCTION
    #
    # So the environment_slug could be dev or production for test or live
    # namespaces.
    #
    ['dev', 'production'].each do |environment_slug|
      puts '=' * 80
      puts "Attempt to publish the form #{service.name} in '#{environment_slug}'"

      last_deployment = service.service_deployments
        .where(status: 'completed')
        .where(environment_slug: environment_slug)
        .order("completed_at ASC").last

      form_url = DeploymentService.url_for(
        service: service,
        environment_slug: environment_slug
      )
      ping_url = "#{form_url}ping.json"

      request = Typhoeus.get(ping_url)
      puts "Requesting to #{ping_url}"
      puts "Check: Is there a Last deployment? #{last_deployment.present?}"
      puts "Check: Is the form published? Status code: #{request.response_code}"

      if last_deployment.blank? || request.response_code != 200
        puts "Skipping..."
        puts '=' * 80
        next
      end

      deployments_params = {
        environment_slug: environment_slug,
        service_id: service.id,
        json_sub_dir: last_deployment.json_sub_dir,
        commit_sha: last_deployment.commit_sha
      }

      deployment = ServiceDeployment.new(
        deployments_params.merge(
          service: service,
          created_by_user: user,
          status: ServiceDeployment::STATUS[:queued]
        )
      )

      if deployment.save
        puts "Re-publishing form '#{service.name}'"
        DeployServiceJob.perform_later(service_deployment_id: deployment.id)
      else
        puts "Not possible to re-publish the form '#{service.name}'"
        puts deployment.errors.full_messages
        puts "Skipping..."
      end
      puts '=' * 80
    end
  end
end
