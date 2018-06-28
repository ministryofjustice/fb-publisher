ALL_ENVS = {
  dev: {
    deployment_adapter: 'minikube',
    kubectl_context: 'minikube',
    name: 'Development',
    namespace: 'formbuilder-services-dev',
    protocol: 'http://',
    url_root: 'minikube.local'
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
    kubectl_context: 'cp-prod',
    name: 'Production',
    namespace: 'formbuilder-services-production',
    protocol: 'https://',
    url_root: 'apps.production.k8s.integration.dsd.io'
  }
}
Rails.configuration.x.service_environments = ALL_ENVS
