require "arel/visitors/mysql"

module Arel
  module Visitors
    class MySQL
      def visit_PluckMap_BuildJsonObject(o, collector)
        collector << "json_object("
        visit o.args, collector
        collector << ")"
      end

      def visit_PluckMap_JsonArrayAggregate(o, collector)
        collector << "json_arrayagg("
        visit o.arg, collector
        collector << ")"
      end
    end
  end
end
