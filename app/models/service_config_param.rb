class ServiceConfigParam < ActiveRecord::Base
  belongs_to :service
  belongs_to :last_updated_by_user, class_name: "User", foreign_key: :last_updated_by_user_id


  validates :name, length: {minimum: 3, maximum: 64},
                   format: {without: /[^A-Z0-9_]/},
                   uniqueness: {scope: [:service_id, :environment_slug], case_sensitive: false}

  validates :value, length: {maximum: 10485760}                 
  validates :environment_slug, inclusion: {in: ServiceEnvironment.all_slugs.map(&:to_s)}

  def self.visible_to(user_or_user_id)
    user_id = user_or_user_id.is_a?(User) ? user_or_user_id.id : user_or_user_id
    joins(:service).where(services: {created_by_user_id: user_id})
  end
end
