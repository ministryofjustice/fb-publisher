class ServiceDeployment < ActiveRecord::Base
  belongs_to :service
  belongs_to :created_by_user, class_name: "User", foreign_key: :created_by_user_id


  validates :commit_sha, length: {maximum: 64},
                   format: {without: /[^a-zA-Z0-9]/}

  validates :environment_slug, inclusion: {in: ServiceEnvironment.all_slugs.map(&:to_s)}

  STATUS = {
    completed: 'completed',
    failed_retryable: 'failed_retryable',
    failed_non_retryable: 'failed_non_retryable',
    queued: 'queued',
    deploying: 'deploying'
  }.freeze

  validates :status, inclusion: {in: STATUS.values}

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

  def update_status(new_status)
    update_attributes(status: STATUS[new_status])
  end

  def complete!
    update_attributes(status: STATUS[:completed], completed_at: Time.now)
  end

  def fail!(retryable: false)
    logger.info "in fail!, retryable: #{retryable}"
    status = retryable ? STATUS[:failed_retryable] : STATUS[:failed_non_retryable]
    update_attributes(status: status, completed_at: Time.now)
    logger.info "attributes updated to #{attributes}"
  end

  def pending?
    [STATUS[:queued], STATUS[:deploying]].include?(status)
  end

  def generate_github_link
    return if service.git_repo_url.blank?

    url_link = service.git_repo_url
    url_link.slice!('.git')
    url_link << '/commit/' << commit_sha
  end

  # Delete the database record
  def remove!
    delete
  end
end
