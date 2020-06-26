class ServiceEnvironment
  attr_accessor :deployment_adapter, :kubectl_context, :name, :friendly_name, :slug,
                :namespace, :protocol, :url_root,
                :user_datastore_url, :user_filestore_url, :submitter_url

  def self.all
    Rails.configuration.x.service_environments.map do |key, values|
      new(values.merge(slug: key))
    end
  end

  def self.all_slugs
    all.map(&:slug)
  end

  def self.find(key)
    all.find do |e|
      e.slug.to_sym == key.to_sym
    end
  end

  def self.where(attrs)
    all.select do |e|
      attrs.all? do |key, value|
        e.send(key.to_sym) == value
      end
    end
  end

  def self.name_of(slug)
    where(slug: slug.to_sym).first.try(:name)
  end

  def initialize(attrs={})
    attrs.each do |key, value|
      self.instance_variable_set("@#{key.to_s}", value) if self.respond_to?(:"#{key.to_s}=")
    end
  end

  # e.g. https://dev-ioj.test.form.service.justice.gov.uk/
  def url_for(service)
    if slug.to_sym == :production
      as_string = [protocol, service.slug, '.', url_root].join
    else
      as_string = [protocol, service.slug, '.', slug, '.', url_root].join
    end

    URI.join(as_string, '/').to_s
  end

  def to_h
    h = {}
    [:kubectl_context, :name, :namespace, :protocol, :url_root, :user_datastore_url, :user_filestore_url].each do |key|
      h[key] = send(key)
    end
    h
  end

  class RoutingConstraint
    def matches?(request)
      ServiceEnvironment.find(request.params[:env]).present?
    end
  end
end
