require "active_record/version"
require "pluck_map/attribute"

module PluckMap
  module Relationships
    class Many < Base
    protected

      def build_select
        node = PluckMap::JsonSubqueryAggregate.new(scope, attributes.to_json_array)

        # On Rails 4.2, `pluck` can't accept Arel nodes
        if ActiveRecord.version.segments.take(2) == [4,2]
          Arel.sql(scope.connection.visitor.compile(node))
        else
          node
        end
      end

      def build_map
        lambda do |results|
          return [] if results.nil?
          results = JSON.parse(results) if results.is_a?(String)
          results.map do |values|
            attributes.each_with_object({}) do |attribute, hash|
              hash[attribute.name] = attribute.exec(values)
            end
          end
        end
      end

    end
  end
end
