# convenience wrapper around the info we get back from Auth0
class Auth0UserSession
  include ActiveModel
  include ActiveModel::Validations

  VALID_EMAIL_DOMAINS = [
    'justice.gov.uk'
  ].freeze

  attr_accessor :user_info, :user_id, :created_at, :new_user

  validate :email_domain_is_valid

  def initialize(params = {})
    self.user_info = params[:user_info]
    self.user_id = params[:user_id]
    self.created_at = params[:created_at]
    self.new_user = params[:new_user]
  end

  def save_to!(actual_session)
    if valid?
      save_to(actual_session)
      self
    else
      raise SignupNotAllowedError.new
    end
  end

  def save_to(actual_session)
    actual_session[:user_info] = user_info
    actual_session[:user_id] = user_id
    actual_session[:created_at] = Time.now.to_i
  end

  def email
    user_info.try(:[], 'info').try(:[], 'email')
  end

  def name
    user_info.try(:[], 'info').try(:[], 'name')
  end

  def new_user?
    self.new_user
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
