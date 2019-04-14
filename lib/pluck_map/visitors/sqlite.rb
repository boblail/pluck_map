require "arel/visitors/sqlite"

module Arel
  module Visitors
    class SQLite
      def visit_PluckMap_BuildJsonObject(o, collector)
        collector << "json_object("
        visit o.args, collector
        collector << ")"
      end

      def visit_PluckMap_JsonArrayAggregate(o, collector)
        collector << "json_group_array(json("
        visit o.arg, collector
        collector << "))"
      end
    end
  end
end
