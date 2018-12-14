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
  validates :token, length: {minimum: 32, maximum: 32}, uniqueness: true

  before_validation :ensure_token_is_present

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

  # called on create, and also when explicitly clicked in the UI
  def generate_token!
    # 16 hex digits == 32 characters == 256 bits in UTF-8
    self.token = SecureRandom.hex(16)
  end

  private


  def ensure_token_is_present
    generate_token! if token.blank?
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
