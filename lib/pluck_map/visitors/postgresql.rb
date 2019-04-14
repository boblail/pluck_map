require "arel/visitors/postgresql"

module Arel
  module Visitors
    class PostgreSQL
      def visit_PluckMap_BuildJsonObject(o, collector)
        collector << "json_build_object("
        visit o.args, collector
        collector << ")"
      end

      def visit_PluckMap_JsonArrayAggregate(o, collector)
        collector << "json_agg("
        visit o.arg, collector
        collector << ")"
      end
    end
  end
end
