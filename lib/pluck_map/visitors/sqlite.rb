require "arel/visitors/sqlite"

module Arel
  module Visitors
    class SQLite
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
        collector << "json_group_array(json("
        visit o.arg, collector
        collector << "))"
      end

      def visit_PluckMap_JsonSubqueryAggregate(o, collector)
        sql = o.scope.select(o.select.as("object")).to_sql
        collector << "COALESCE((SELECT json_group_array(json(d.object)) FROM (#{sql}) AS d), json_array())"
      end
    end
  end
end
