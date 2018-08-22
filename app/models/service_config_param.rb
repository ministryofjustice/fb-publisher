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
    # NOTE: won't scale beyond 500 services visible to this user
    where("service_id IN(?)", Service.visible_to(user_id).pluck(:id))
  end

  def is_visible_to?(user_or_user_id)
    service.is_visible_to?(user_or_user_id)
  end

  def self.key_value_pairs(scope)
    scope.index_by(&:name).inject({}) do |hash, val|
      hash[val.first] = val.last.value
      hash
    end
  end

end
