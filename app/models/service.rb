class Service < ActiveRecord::Base
  include Concerns::HasSlug

  DEPLOY_KEY_REGEX = /\A[=+\/\n\rA-Za-z0-9 -]+\z/

  belongs_to :created_by_user, class_name: "User", foreign_key: :created_by_user_id

  has_many :service_config_params, dependent: :destroy
  has_many :permissions, dependent: :destroy
  has_many :teams, through: :permissions
  has_many :service_deployments, dependent: :destroy

  validates :name, length: {minimum: 3, maximum: 128}, uniqueness: true
  validates :git_repo_url, presence: true, length: {minimum: 8, maximum: 1024}
  validates :deploy_key, format: { with: DEPLOY_KEY_REGEX, allow_blank: true }
  validate  :check_git_repo_url

  after_create :generate_secret_config_params

  scope :contains, -> (name) { where("lower(name) like ?", "%#{name}%".downcase)}

  def service_token_for_environment(environment_slug)
    service_config_params.find_by(name: 'SERVICE_TOKEN', environment_slug: environment_slug)
  end

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

  def check_git_repo_url
    if git_repo_url && git_repo_url.starts_with?('git@')
      uri = URI::SshGit.parse(git_repo_url)

      check_url_user_is_git(uri)
      check_url_host_is_github(uri)
      check_url_path_is_present(uri)
    else
      begin
        uri = URI.parse(self.git_repo_url)

        check_url_permitted_scheme(uri)
      rescue URI::InvalidURIError => e
        errors.add(:git_repo_url, I18n.t(:invalid_uri, scope: [:errors, :service, :git_repo_url]))
      end
    end
  end

  def check_url_permitted_scheme(uri)
    unless ['https', 'file', ''].include?(uri.scheme)
      errors.add(:git_repo_url, I18n.t(:not_valid_scheme, scope: [:errors, :service, :git_repo_url]))
    end
  end

  def check_url_user_is_git(uri)
    unless uri.user == 'git'
      errors.add(:git_repo_url, I18n.t(:not_valid_git, scope: [:errors, :service, :git_repo_url]))
    end
  end

  def check_url_host_is_github(uri)
    unless uri.host == 'github.com'
      errors.add(:git_repo_url, I18n.t(:not_valid_git, scope: [:errors, :service, :git_repo_url]))
    end
  end

  def check_url_path_is_present(uri)
    unless uri.path.present?
      errors.add(:git_repo_url, I18n.t(:not_valid_git, scope: [:errors, :service, :git_repo_url]))
    end
  end
end
