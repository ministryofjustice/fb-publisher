ALL_ENVS = {
  dev: {
    deployment_adapter: 'cloud_platform',
    kubectl_context: 'cp-non-prod',
    name: 'Development',
    namespace: 'formbuilder-services-dev',
    protocol: 'https://',
    url_root: 'apps.non-production.k8s.integration.dsd.io'
  },
  staging: {
    deployment_adapter: 'cloud_platform',
    kubectl_context: 'cp-non-prod',
    name: 'Staging',
    namespace: 'formbuilder-services-staging',
    protocol: 'https://',
    url_root: 'apps.non-production.k8s.integration.dsd.io'
  },
  production: {
    deployment_adapter: 'cloud_platform',
    kubectl_context: 'cp-live',
    name: 'Production',
    namespace: 'formbuilder-services-production',
    protocol: 'https://',
    url_root: 'apps.production.k8s.integration.dsd.io'
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
