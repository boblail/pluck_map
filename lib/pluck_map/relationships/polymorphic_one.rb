require "pluck_map/attribute"

module PluckMap
  module Relationships
    class PolymorphicOne < Attribute

      def initialize(attribute_name, reflection, block, options)
        @reflection = reflection
        @attributes_block = block
        @scope_block = options[:scope_block]

        options = options.slice(:as).merge(
          select: [ reflection.foreign_type.to_sym, reflection.foreign_key.to_sym ],
          map: ->(*args) { @preloads[args] })

        super(attribute_name, reflection.active_record, options)
      end

      def nested?
        true
      end

      def preload!(results)
        ids_by_type = Hash.new { |hash, key| hash[key] = [] }

        results.each do |values|
          type, id = values.values_at(*indexes)
          ids_by_type[type].push(id)
        end

        @preloads = Hash.new
        ids_by_type.each do |type, ids|
          klass = type.constantize
          scope = klass.where(id: ids)
          scope = scope.instance_exec(&@scope_block) if @scope_block

          presenter = PluckMap[klass].define do |q|
            q.__id select: klass.primary_key.to_sym

            if @attributes_block.arity == 1
              @attributes_block.call(q)
            else
              q.instance_eval(&@attributes_block)
            end
          end

          presenter.to_h(scope).each do |h|
            id = h.delete(:__id)
            @preloads[[type, id]] = h
          end
        end

        nil
      end

    end
  end
end
