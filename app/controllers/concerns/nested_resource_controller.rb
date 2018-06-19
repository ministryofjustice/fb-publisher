module Concerns
  module NestedResourceController
    extend ActiveSupport::Concern

    included do
      private

      def nest_under(resource_name, attr_name: :id, resource_class: nil, param_name: nil)
        param_name ||= [resource_name.to_s, 'id'].join('_')
        resource_class ||= resource_name.to_s.classify.constantize

        load_and_authorize_parent_resource!(  resource_name,
                                              resource_class: resource_class,
                                              attr_name: attr_name,
                                              param_name: param_name)
      end

      def load_parent_resource!( resource_class, attr_name: :id, param_name: :id)
        resource_class.send(:"find_by_#{attr_name.to_s}", params[param_name])
      end

      def load_and_authorize_parent_resource!(  resource_name,
                                                resource_class: nil,
                                                attr_name: :id,
                                                param_name: nil,
                                                parent_action: :show )
        parent = load_parent_resource!(resource_class,
                                       attr_name: attr_name,
                                       param_name: param_name)
        instance_variable_set("@#{resource_name}", parent)
        authorize(parent, parent_action)
      end
    end
  end
end
