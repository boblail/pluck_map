require "pluck_map/attribute"

module PluckMap
  module Relationships
    class Base < Attribute
      attr_reader :attributes, :scope

      def initialize(attribute_name, scope, block, options)
        @scope = scope
        @attributes = AttributeBuilder.build(model: scope.klass, &block)
        @scope = @scope.instance_exec(&options[:scope_block]) if options[:scope_block]
        options = options.slice(:as).merge(
          select: build_select,
          map: build_map)

        super(attribute_name, scope.klass, options)
      end

      def will_map?
        attributes.any?(&:will_map?)
      end

      def nested?
        true
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
