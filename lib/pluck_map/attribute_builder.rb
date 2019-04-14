require "pluck_map/attribute"

module PluckMap
  class AttributeBuilder

    def self.build(&block)
      builder = self.new
      if block.arity == 1
        block.call(builder)
      else
        builder.instance_eval(&block)
      end
      builder.instance_variable_get(:@attributes).freeze
    end

    def initialize
      @attributes = []
    end

    def method_missing(attribute_name, *args)
      options = args.extract_options!
      options[:value] = args.first unless args.empty?
      @attributes.push PluckMap::Attribute.new(attribute_name, options)
      :attribute_added
    end

  end
end
