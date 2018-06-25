class ServiceDeployment < ActiveRecord::Base
  belongs_to :service
  belongs_to :created_by_user, class_name: "User", foreign_key: :created_by_user_id


  validates :commit_sha, length: {minimum: 6, maximum: 64},
                   format: {without: /[^a-zA-Z0-9]/}

  validates :environment_slug, inclusion: {in: ServiceEnvironment.all_slugs.map(&:to_s)}

  def self.latest(service_id:, environment_slug:)
    where(  service_id: service_id,
            environment_slug: environment_slug)
    .order('created_at desc')
    .first
  end
  
  def self.visible_to(user_or_user_id)
    user_id = user_or_user_id.is_a?(User) ? user_or_user_id.id : user_or_user_id
    joins(:service).where(services: {created_by_user_id: user_id})
  end
end
