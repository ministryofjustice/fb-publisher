class ServiceEnvironment
  attr_accessor :kubectl_context, :name, :slug, :namespace, :protocol, :url_root

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

  def initialize(attrs={})
    attrs.each do |key, value|
      self.instance_variable_set("@#{key.to_s}", value) if self.respond_to?(:"#{key.to_s}=")
    end
  end

  def url_for(service)
    as_string = [protocol, service.slug, '.', url_root].join
    URI.join(as_string, '/').to_s
  end

  def to_h
    h = {}
    [:kubectl_context, :name, :namespace, :protocol, :url_root].each do |key|
      h[key] = send(key)
    end
    h
  end
end
