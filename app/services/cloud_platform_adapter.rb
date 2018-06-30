class CloudPlatformAdapter
  # can be called before the service is deployed
  def self.url_for(service:, environment_slug:)
    ServiceEnvironment.find(environment_slug).url_for(service)
  end

  def self.service_url(service:, environment_slug:)
    environment = ServiceEnvironment.find(environment_slug)
    KubernetesAdapter.service_url(
      service: service,
      environment_slug: environment_slug,
      context: environment.kubectl_context,
      namespace: environment.namespace
    )
  end
end
