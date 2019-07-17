require "pluck_map/association_scope"
require "pluck_map/relationships/base"
require "pluck_map/relationships/many"
require "pluck_map/relationships/one"
require "pluck_map/relationships/polymorphic_one"

module PluckMap
  module Relationships
    class << self

      def one(model, name, block, options)
        reflection = reflection_for(model, name)
        if reflection.polymorphic?
          Relationships::PolymorphicOne.new(name, reflection, block, options)
        else
          Relationships::One.new(name, scope_for_reflection(reflection), block, options)
        end
      end

      def many(model, name, block, options)
        Relationships::Many.new(name, scope(model, name), block, options)
      end

    private

      def scope(model, name)
        scope_for_reflection(reflection_for(model, name))
      end

      def scope_for_reflection(reflection)
        scope_for(association_for(reflection))
      end

      def reflection_for(model, name)
        # Use `_reflections.fetch(name)` instead of `reflect_on_association(name)`
        # because they have different behavior when it comes to HasAndBelongsToMany
        # associations.
        #
        # `reflect_on_association` will return a HasAndBelongsToManyReflection
        # while `_reflections.fetch(name)` will return a ThroughReflection that
        # wraps a HasAndBelongsToManyReflection.
        #
        # ActiveRecord::Associations::AssociationScope expects the latter.
        #
        model._reflections.fetch(name.to_s) do
          raise ArgumentError, "#{name} is not an association on #{model}"
        end
      end

      def association_for(reflection)
        owner = AbstractOwner.new(reflection)
        reflection.association_class.new(owner, reflection)
      end

      def scope_for(association)
        default_scope_for(association).merge(AssociationScope.create.scope(association))
      end

      def default_scope_for(association)
        association.klass.all
      end

      # ActiveRecord constructs an Association from a Reflection and an
      # Owner. It expects Owner to be an instance of an ActiveRecord object
      # and uses `[]` to access specific values for fields on the record.
      #
      #    e.g. WHERE books.author_id = 7
      #
      # We want to create a subquery that will reference those fields
      # but not their specific values.
      #
      #    e.g. WHERE books.author_id = authors.id
      #
      # So we create an object that serves the purpose of Owner but returns
      # appropriate selectors.
      #
      AbstractOwner = Struct.new(:reflection) do
        def class
          reflection.active_record
        end

        def [](value)
          self.class.arel_table[value]
        end
      end

    end
  end
end
