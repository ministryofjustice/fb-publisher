module Concerns
  module NestedResourceController
    extend ActiveSupport::Concern

    included do
      private

      def self.nest_under(resource_name,
                          attr_name: :id,
                          resource_class: nil,
                          param_name: nil,
                          parent_action: :show)
        param_name ||= [resource_name.to_s, 'id'].join('_')
        resource_class ||= resource_name.to_s.classify.constantize

        options = {
          resource_name: resource_name,
          resource_class: resource_class,
          attr_name: attr_name,
          param_name: param_name,
          parent_action: parent_action
        }
        # note: this will be an instance variable on the *class*
        instance_variable_set("@nested_resource_options", options)

        before_action :load_and_authorize_parent_resource!
      end

      def load_parent_resource!( resource_class, attr_name: :id, param_name: :id)
        resource_class.send(:"find_by_#{attr_name.to_s}", params[param_name])
      end

      def load_and_authorize_parent_resource!( options={} )
        options = self.class.send(:instance_variable_get, '@nested_resource_options')\
                            .to_h\
                            .merge(options)
        options[:parent_action] ||= :show

        parent = load_parent_resource!(options[:resource_class],
                                       attr_name: options[:attr_name],
                                       param_name: options[:param_name])
        instance_variable_set("@#{options[:resource_name]}", parent)
        authorize(parent, "#{options[:parent_action].to_s}?".to_sym)
      end
    end
  end
end
