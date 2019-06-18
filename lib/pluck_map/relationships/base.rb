require "pluck_map/structured_attribute"

module PluckMap
  module Relationships
    class Base < StructuredAttribute
      attr_reader :scope

      def initialize(attribute_name, scope, block, options)
        @scope = scope
        @scope = @scope.instance_exec(&options[:scope_block]) if options[:scope_block]
        super(attribute_name, scope.klass, block, options)
      end

    protected

      def build_select
        raise NotImplementedError
      end

      def build_map
        raise NotImplementedError
      end

    end
  end
end
