require "arel"

module PluckMap
  class BuildJsonObject < Arel::Nodes::Node
    include Arel::AliasPredication

    attr_reader :args

    def initialize(*args)
      @args = args
    end
  end

  class BuildJsonArray < Arel::Nodes::Node
    include Arel::AliasPredication

    attr_reader :args

    def initialize(*args)
      @args = args
    end
  end

  class JsonArrayAggregate < Arel::Nodes::Node
    attr_reader :arg

    def initialize(arg)
      @arg = arg
    end
  end

  class JsonSubqueryAggregate < Arel::Nodes::Node
    attr_reader :scope, :select

    def initialize(scope, select)
      @scope = scope
      @select = select
    end
  end
end
