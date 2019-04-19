require "pluck_map/attribute"
require "pluck_map/attributes"

module PluckMap
  class AttributeBuilder < BasicObject

    def self.build(&block)
      attributes = []
      builder = self.new(attributes)
      if block.arity == 1
        block.call(builder)
      else
        builder.instance_eval(&block)
      end
      Attributes.new(attributes)
    end

    def initialize(attributes)
      @attributes = attributes
    end

    def method_missing(attribute_name, *args)
      options = args.extract_options!
      options[:value] = args.first unless args.empty?
      @attributes.push Attribute.new(attribute_name, options)
      :attribute_added
    end

  end
end
