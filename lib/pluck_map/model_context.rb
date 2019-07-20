require "pluck_map/presenter"

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

      klass
    end
  end
end
