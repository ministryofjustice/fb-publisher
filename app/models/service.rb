class Service < ActiveRecord::Base
  include Concerns::HasSlug

  belongs_to :created_by_user, class_name: "User", foreign_key: :created_by_user_id

  has_many :service_status_checks, dependent: :destroy
  has_many :service_config_params, dependent: :destroy
  #has_many :service_permissions, dependent: :destroy
  has_many :service_deployments, dependent: :destroy

  validates :name, length: {minimum: 3, maximum: 128}, uniqueness: true
  validates :git_repo_url, presence: true, length: {minimum: 8, maximum: 1024}
  validate  :git_repo_url_must_use_https

  # Naive first impl - just services created by the given user
  # TODO: revisit once we have concept of teams
  def self.visible_to(user_or_user_id)
    user_id = user_or_user_id.is_a?(User) ? user_or_user_id.id : user_or_user_id
    where(created_by_user_id: user_id)
  end



  private



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
