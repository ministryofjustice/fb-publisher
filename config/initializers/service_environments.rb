PLATFORM_ENV = ENV['PLATFORM_ENV']

url_root = if ENV['PLATFORM_ENV'] == 'live'
             "form.service.justice.gov.uk"
           else
             "#{ENV['PLATFORM_ENV']}.form.service.justice.gov.uk"
           end

# TODO: de-duplicate set up of dev, staging and production
ALL_ENVS = {
  dev: {
    deployment_adapter: 'cloud_platform',
    kubectl_context: ENV['KUBECTL_CONTEXT'],
    name: 'Development',
    namespace: "formbuilder-services-#{ENV['PLATFORM_ENV']}-dev",
    protocol: 'https://',
    url_root: url_root,
    user_datastore_url: "http://fb-user-datastore-api-svc-#{ENV['PLATFORM_ENV']}-dev.formbuilder-platform-#{ENV['PLATFORM_ENV']}-dev/",
    user_filestore_url: "http://fb-user-filestore-api-svc-#{ENV['PLATFORM_ENV']}-dev.formbuilder-platform-#{ENV['PLATFORM_ENV']}-dev/",
    submitter_url: "http://fb-submitter-api-svc-#{ENV['PLATFORM_ENV']}-dev.formbuilder-platform-#{ENV['PLATFORM_ENV']}-dev/"
  },
  staging: {
    deployment_adapter: 'cloud_platform',
    kubectl_context: ENV['KUBECTL_CONTEXT'],
    name: 'Staging',
    namespace: "formbuilder-services-#{ENV['PLATFORM_ENV']}-staging",
    protocol: 'https://',
    url_root: url_root,
    user_datastore_url: "http://fb-user-datastore-api-svc-#{ENV['PLATFORM_ENV']}-staging.formbuilder-platform-#{ENV['PLATFORM_ENV']}-staging/",
    user_filestore_url: "http://fb-user-filestore-api-svc-#{ENV['PLATFORM_ENV']}-staging.formbuilder-platform-#{ENV['PLATFORM_ENV']}-staging/",
    submitter_url: "http://fb-submitter-api-svc-#{ENV['PLATFORM_ENV']}-staging.formbuilder-platform-#{ENV['PLATFORM_ENV']}-staging/"
  },
  production: {
    deployment_adapter: 'cloud_platform',
    kubectl_context: ENV['KUBECTL_CONTEXT'],
    name: 'Production',
    namespace: "formbuilder-services-#{ENV['PLATFORM_ENV']}-production",
    protocol: 'https://',
    url_root: url_root,
    user_datastore_url: "http://fb-user-datastore-api-svc-#{ENV['PLATFORM_ENV']}-production.formbuilder-platform-#{ENV['PLATFORM_ENV']}-production/",
    user_filestore_url: "http://fb-user-filestore-api-svc-#{ENV['PLATFORM_ENV']}-production.formbuilder-platform-#{ENV['PLATFORM_ENV']}-production/",
    submitter_url: "http://fb-submitter-api-svc-#{ENV['PLATFORM_ENV']}-production.formbuilder-platform-#{ENV['PLATFORM_ENV']}-production/"
  }
}

# only use minikube on local machines - i.e. dev
envs = ALL_ENVS
# Note: Rails.environment is not set up at this point in the initialization
if ['development'].include?(ENV['RAILS_ENV'])
  envs[:localhost] = {
    deployment_adapter: 'minikube',
    kubectl_context: 'minikube',
    name: 'localhost',
    namespace: 'formbuilder-services-localhost',
    protocol: 'http://',
    url_root: 'minikube.local'
  }
end

Rails.configuration.x.service_environments = envs
