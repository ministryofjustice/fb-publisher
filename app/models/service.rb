class Service < ActiveRecord::Base
  include Concerns::HasSlug

  belongs_to :created_by_user, class_name: "User", foreign_key: :created_by_user_id

  has_many :service_status_checks, dependent: :destroy
  has_many :service_config_params, dependent: :destroy
  has_many :permissions, dependent: :destroy
  has_many :teams, through: :permissions
  has_many :service_deployments, dependent: :destroy

  validates :name, length: {minimum: 3, maximum: 128}, uniqueness: true
  validates :git_repo_url, presence: true, length: {minimum: 8, maximum: 1024}
  validate  :git_repo_url_must_use_https

  after_create :generate_secret_config_params

  scope :contains, -> (name) { where("lower(name) like ?", "%#{name}%".downcase)}

  # NOTE: uses same naive implementation as Team.visible_to -
  # two separate queries for IDs, then a single WHERE id IN(?)
  # Which will not scale well past a few hundred IDs
  def self.visible_to(user_or_user_id)
    user_id = user_or_user_id.is_a?(User) ? user_or_user_id.id : user_or_user_id
    service_ids = where(created_by_user_id: user_id).pluck(:id)
    service_ids += with_permissions_for_user(user_id).pluck(:id)

    where("id IN(?)", service_ids.uniq)
  end

  def is_visible_to?(user_or_user_id)
    user_id = user_or_user_id.is_a?(User) ? user_or_user_id.id : user_or_user_id

    created_by_user_id == user_id || \
      Permission.for_user_id(user_id).where(service_id: self.id).exists?
  end

  def self.with_permissions_for_user(user_id)
    joins(:permissions).joins(permissions: :team) \
                       .joins(permissions: {team: :members}) \
                       .where(team_members: {user_id: user_id})
  end

  private

  def generate_secret_config_params
    ServiceEnvironment.all_slugs.each do |slug|
      ServiceConfigParam.create(environment_slug: slug, name: 'SERVICE_TOKEN', value: SecureRandom.hex(16), service: self, last_updated_by_user: self.created_by_user, privileged: true)

      ServiceConfigParam.create(environment_slug: slug, name: 'SERVICE_SECRET', value: SecureRandom.hex(16), service: self, last_updated_by_user: self.created_by_user, privileged: true)
    end
  end

  def git_repo_url_must_use_https
    begin
      uri = URI.parse(self.git_repo_url)
      unless ['https', 'file', ''].include?(uri.scheme)
        errors.add(:git_repo_url, I18n.t(:not_valid_scheme, scope: [:errors, :service, :git_repo_url]))
      end

    rescue URI::InvalidURIError => e
      errors.add(:git_repo_url, I18n.t(:invalid_uri, scope: [:errors, :service, :git_repo_url]))
    end
  end
end
