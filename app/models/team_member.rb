class TeamMember < ActiveRecord::Base
  include Concerns::CreatedByUser

  belongs_to :team
  belongs_to :user
end
