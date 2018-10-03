ALL_ENVS = {
  dev: {
    deployment_adapter: 'cloud_platform',
    kubectl_context: ENV['KUBECTL_CONTEXT'],
    name: 'Development',
    namespace: 'formbuilder-services-dev',
    protocol: 'https://',
    url_root: 'apps.cloud-platform-live-0.k8s.integration.dsd.io',
    user_datastore_url: 'http://fb-user-datastore-api-svc-dev.formbuilder-platform-dev/'
  },
  staging: {
    deployment_adapter: 'cloud_platform',
    kubectl_context: ENV['KUBECTL_CONTEXT'],
    name: 'Staging',
    namespace: 'formbuilder-services-staging',
    protocol: 'https://',
    url_root: 'apps.cloud-platform-live-0.k8s.integration.dsd.io',
    user_datastore_url: 'http://fb-user-datastore-api-svc-staging.formbuilder-platform-staging/'
  },
  production: {
    deployment_adapter: 'cloud_platform',
    kubectl_context: ENV['KUBECTL_CONTEXT'],
    name: 'Production',
    namespace: 'formbuilder-services-production',
    protocol: 'https://',
    url_root: 'apps.cloud-platform-live-0.k8s.integration.dsd.io',
    user_datastore_url: 'http://fb-user-datastore-api-svc-production.formbuilder-platform-production/'
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
