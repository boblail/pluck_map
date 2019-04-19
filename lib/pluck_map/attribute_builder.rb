require "pluck_map/attribute"
require "pluck_map/attributes"
require "pluck_map/relationships"

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
      Attributes.new(attributes, model)
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

    def has_many(name, *args, &block)
      options = args.extract_options!
      options[:scope_block] = args.first unless args.empty?
      @attributes.push Relationships.many(@model, name, block, options)
      :relationship_added
    end

    def has_one(name, *args, &block)
      options = args.extract_options!
      options[:scope_block] = args.first unless args.empty?
      @attributes.push Relationships.one(@model, name, block, options)
      :relationship_added
    end

  end
end
