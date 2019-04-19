require "pluck_map/attribute"

module PluckMap
  module Relationships
    class One < Base
    protected

      def build_select
        Arel.sql("(#{scope.select(attributes.to_json_array).to_sql})")
      end

      def build_map
        lambda do |values|
          return nil if values.nil?
          values = JSON.parse(values) if values.is_a?(String)
          attributes.each_with_object({}) do |attribute, hash|
            hash[attribute.name] = attribute.exec(values)
          end
        end
      end

    end
  end
end
