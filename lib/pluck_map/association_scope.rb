require "active_record"

# ActiveRecord::Associations::AssociationScope assumes that values
# for Owner's fields will be concrete values that need to be type-cast.
#
# But our AbstractOwner returns field references (Arel::Attributes::Attribute)
# and we need them to bypass type-casting.
#
module PluckMap
  module AssociationScope
    def self.[](version)
      const_get "Rails#{version.to_s.delete(".")}"
    end

    def self.create
      case ActiveRecord.version.segments.take(2)
      when [4,2] then self[4.2].create
      when [5,0] then self[5.0].create
      else self::Current.create
      end
    end


    # Rails 5.1+
    class Current < ActiveRecord::Associations::AssociationScope
      def apply_scope(scope, table, key, value)
        if value.is_a?(Arel::Attributes::Attribute)
          scope.where!(table[key].eq(value))
        else
          super
        end
      end

      def scope(association)
        if ActiveRecord.version.version < "5.2"
          super(association, association.reflection.active_record.connection)
        else
          super
        end
      end
    end


    # In Rails 5.0, `apply_scope` isn't extracted from `last_chain_scope`
    # and `next_chain_scope` so we have to override the entire methods to
    # extract `apply_scope` and bypass type-casting.
    #
    # Refer to https://github.com/rails/rails/blob/v5.0.7.2/activerecord/lib/active_record/associations/association_scope.rb#L61-L94
    #
    class Rails50 < Current
      def last_chain_scope(scope, table, reflection, owner, association_klass)
        join_keys = reflection.join_keys(association_klass)
        key = join_keys.key
        foreign_key = join_keys.foreign_key

        value = transform_value(owner[foreign_key])
        scope = apply_scope(scope, table, key, value)

        if reflection.type
          polymorphic_type = transform_value(owner.class.base_class.name)
          scope = scope.where(table.name => { reflection.type => polymorphic_type })
        end

        scope
      end

      def next_chain_scope(scope, table, reflection, association_klass, foreign_table, next_reflection)
        join_keys = reflection.join_keys(association_klass)
        key = join_keys.key
        foreign_key = join_keys.foreign_key

        constraint = table[key].eq(foreign_table[foreign_key])

        if reflection.type
          value = transform_value(next_reflection.klass.base_class.name)
          scope = apply_scope(scope, table, reflection.type, value)
        end

        scope = scope.joins(join(foreign_table, constraint))
      end

      def apply_scope(scope, table, key, value)
        if value.is_a?(Arel::Attributes::Attribute)
          scope.where(table[key].eq(value))
        else
          scope.where(table.name => { key => value })
        end
      end
    end


    class Rails42 < Current
      def bind(_, _, _, value, _)
        if value.is_a?(Arel::Attributes::Attribute)
          value
        else
          super
        end
      end
    end
  end
end
