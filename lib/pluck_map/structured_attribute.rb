require "pluck_map/attribute"

module PluckMap
  class StructuredAttribute < Attribute
    attr_reader :attributes

    def initialize(id, model, block, options={})
      @model = model
      @attributes = AttributeBuilder.build(model: model, &block)
      options = options.slice(:as).merge(
        select: attributes.selects,
        map: build_map)

      super(id, model, options)
    end

    def will_map?
      attributes.any?(&:will_map?)
    end

    def nested?
      true
    end

  private

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
