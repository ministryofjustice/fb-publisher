class Service < ActiveRecord::Base
  belongs_to :created_by_user, class_name: "User", foreign_key: :created_by_user_id

  has_many :service_status_checks
  has_many :service_config_params
  has_many :service_permissions
  has_many :service_deployments

  before_validation :generate_slug_if_blank!

  validates :name, length: {minimum: 3, maximum: 128}, uniqueness: true
  validates :slug, length: {maximum: 64, minimum: 3}, uniqueness: true

  # Naive first impl - just services created by the given user
  # TODO: revisit once we have concept of teams
  def self.visible_to(user_or_user_id)
    user_id = user_or_user_id.is_a?(User) ? user_or_user_id.id : user_or_user_id
    where(created_by_user_id: user_id)
  end

  def to_param
    slug
  end

  private

  def generate_slug_if_blank!
    return unless slug.blank?
    self.slug = to_slug
  end

  def to_slug(string=name)
    string.gsub(/[^[:alnum:]\-]+/i, '-')\
          .gsub(/^\-*(.*)/, '\1')\
          .gsub(/(.*)\-+$/, '\1')\
          .downcase
  end
end
