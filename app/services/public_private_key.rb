require 'openssl'

class PublicPrivateKey
  def initialize
    @rsa_key = OpenSSL::PKey::RSA.new(2048)
  end

  def public_key
    rsa_key.public_key.to_pem
  end

  def private_key
    rsa_key.to_pem
  end

  private

  attr_reader :rsa_key
end
