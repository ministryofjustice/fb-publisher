class User < ActiveRecord::Base
  has_many :identities, dependent: :destroy
end
