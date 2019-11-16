require "pluck_map/presenter"
require "pluck_map/struct"

module PluckMap
  class ModelContext
    def initialize(model)
      @model = model
    end

    def define(&block)
      attributes = PluckMap::AttributeBuilder.build(model: @model, &block)
      define_class!(@model, attributes)
    end

  private

    def define_class!(model, attributes)
      # Create a new subclass of PluckMap::Presenter
      klass = Class.new(PluckMap::Presenter)

      # Partially apply initialize with the parameters passed to this method
      klass.define_method(:initialize) do |query|
        super(model, attributes, query)
      end

      # Generate a Struct constant in the namespace of the new subclass
      struct = ::Struct.new(*attributes.ids, keyword_init: true)
      struct.extend PluckMap::Struct::ClassMethods
      struct.instance_variable_set :@presenter, klass
      klass.const_set :Struct, struct

      klass
    end
  end
end
