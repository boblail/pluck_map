require "pluck_map/attribute"
require "pluck_map/attributes"

module PluckMap
  class AttributeBuilder < BasicObject

    def self.build(model:, &block)
      attributes = []
      builder = self.new(attributes, model)
      if block.arity == 1
        block.call(builder)
      else
        builder.instance_eval(&block)
      end
      Attributes.new(attributes)
    end

    def initialize(attributes, model)
      @attributes = attributes
      @model = model
    end

    def method_missing(attribute_name, *args)
      options = args.extract_options!
      options[:value] = args.first unless args.empty?
      @attributes.push Attribute.new(attribute_name, @model, options)
      :attribute_added
    end

  end
end
