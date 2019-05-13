require "arel/visitors/postgresql"

module Arel
  module Visitors
    class PostgreSQL
      def visit_PluckMap_BuildJsonObject(o, collector)
        collector << "json_build_object("
        visit o.args, collector
        collector << ")"
      end

      def visit_PluckMap_BuildJsonArray(o, collector)
        collector << "json_build_array("
        visit o.args, collector
        collector << ")"
      end

      def visit_PluckMap_JsonArrayAggregate(o, collector)
        collector << "json_agg("
        visit o.arg, collector
        collector << ")"
      end

      def visit_PluckMap_JsonSubqueryAggregate(o, collector)
        sql = o.scope.select(o.select.as("object")).to_sql
        collector << "COALESCE((SELECT json_agg(d.object) FROM (#{sql}) AS d), json_build_array())"
      end
    end
  end
end
