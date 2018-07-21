class Permission < ActiveRecord::Base
  include Concerns::CreatedByUser
  
  belongs_to :team
  belongs_to :service
end
