def create_service(service)
  visit '/services/new'
  fill_in :service_name, with: service.name
  fill_in :service_slug, with: service.slug
  fill_in :service_git_repo_url, with: service.git_repo_url
  click_button 'Create form'
end

def add_environment_variable(service:, name:, value:, environment:)
  visit "/services/#{service.slug}/config_params"
  fill_in('Name', with: name)
  fill_in('Value', with: value)
  click_button 'Add'
end

def edit_environment_variable(service:, name:, value:, environment:)
  visit "/services/#{service.slug}/config_params"
end
