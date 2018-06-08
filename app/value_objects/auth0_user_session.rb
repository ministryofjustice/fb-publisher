# convenience wrapper around the info we get back from Auth0
class Auth0UserSession
  include ActiveModel
  include ActiveModel::Validations

  VALID_EMAIL_DOMAINS = [
    'justice.gov.uk'
  ].freeze

  attr_accessor :user_info, :user_id

  validate :email_domain_is_valid

  def initialize(params = {})
    self.user_id = params[:user_id]
    self.user_info = params[:user_info]
  end

  def save_to(actual_session)
    actual_session[:user_info] = user_info
    actual_session[:user_id] = user_id
  end

  def email
    user_info.try(:[], 'info').try(:[], 'email')
  end

  def name
    user_info.try(:[], 'info').try(:[], 'name')
  end

  private

  def email_domain_is_valid
    # v. naive validator - does the given email end with
    # justice.gov.uk ?
    errors.add(:user_info, "email must end with one of #{VALID_EMAIL_DOMAINS}") \
      unless VALID_EMAIL_DOMAINS.any? do |domain|
        email.to_s.ends_with?(domain)
      end
  end
end
