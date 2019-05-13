require "arel/visitors/mysql"

module Arel
  module Visitors
    class MySQL
      def visit_PluckMap_BuildJsonObject(o, collector)
        collector << "json_object("
        visit o.args, collector
        collector << ")"
      end

      def visit_PluckMap_BuildJsonArray(o, collector)
        collector << "json_array("
        visit o.args, collector
        collector << ")"
      end

      def visit_PluckMap_JsonArrayAggregate(o, collector)
        collector << "json_arrayagg("
        visit o.arg, collector
        collector << ")"
      end

      def visit_PluckMap_JsonSubqueryAggregate(o, collector)
        interior = compile(o.select)
        if o.scope.order_values.present?
          interior = "#{interior} ORDER BY #{compile(o.scope.order_values)}"
        end
        interior = "CAST(CONCAT('[',GROUP_CONCAT(#{interior}),']') AS JSON)"
        sql = o.scope.reorder(nil).select(Arel.sql(interior)).to_sql

        collector << "COALESCE((#{sql}), json_array())"
      end
    end
  end
end
