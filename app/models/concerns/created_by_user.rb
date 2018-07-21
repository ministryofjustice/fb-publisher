require 'active_support/concern'

module Concerns
  module CreatedByUser
    extend ActiveSupport::Concern

    included do
      belongs_to  :created_by_user, class_name: "User", foreign_key: :created_by_user_id

      def self.created_by_user(user_id)
        where(created_by_user: user_id)
      end
    end
  end
end
