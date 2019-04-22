require "pluck_map/presenter"

module PluckMap
  class ModelContext
    def initialize(model)
      @model = model
    end

    def define(&block)
      attributes = PluckMap::AttributeBuilder.build(model: @model, &block)
      PluckMap::Presenter.new(@model, attributes)
    end
  end
end
