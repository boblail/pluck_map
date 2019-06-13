require "pluck_map/attribute"

module PluckMap
  class StructuredAttribute < Attribute
    attr_reader :attributes

    def initialize(attribute_name, model, block, options={})
      @attributes = AttributeBuilder.build(model: model, &block)
      options = options.slice(:as).merge(select: build_select, map: build_map)
      super(attribute_name, model, options)
    end

    def will_map?
      attributes.any?(&:will_map?)
    end

    def nested?
      true
    end

  protected

    def build_select
      attributes.selects
    end

    def build_map
      lambda do |*values|
        return nil if values.none?
        attributes.each_with_object({}) do |attribute, hash|
          hash[attribute.name] = attribute.exec(values)
        end
      end
    end

  end
end
