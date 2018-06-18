class User < ActiveRecord::Base
  has_many :identities, dependent: :destroy
  has_many :services_as_creator, foreign_key: :created_by_user_id, class_name: "Service"
end
