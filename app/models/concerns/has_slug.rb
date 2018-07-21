require 'active_support/concern'

module Concerns
  module HasSlug
    extend ActiveSupport::Concern

    included do
      validates :slug, length: {maximum: 64, minimum: 3}, uniqueness: true
      before_validation :generate_slug_if_blank!
      
      def to_param
        slug
      end

      private

      def to_slug(string=name)
        return if string.empty?
        string.gsub(/[^[:alnum:]\-]+/i, '-')\
              .gsub(/^\-*(.*)/, '\1')\
              .gsub(/(.*)\-+$/, '\1')\
              .downcase
      end

      def generate_slug_if_blank!
        return unless slug.blank?
        self.slug = to_slug
      end

    end

    class_methods do

    end

  end
end
