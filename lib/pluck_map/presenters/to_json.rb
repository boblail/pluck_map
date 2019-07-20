require "json"

module PluckMap
  module JsonPresenter

    def self.included(base)
      def base.to_json(query, **kargs)
        new(query).to_json(**kargs)
      end
    end

    def to_json(json: default_json, **)
      if attributes.will_map?
        to_json__default(json: json)
      else
        to_json__optimized
      end
    end

  private

    def to_json__default(json: default_json, **)
      json.dump(to_h)
    end

    def to_json__optimized(**)
      define_to_json__optimized!
      to_json__optimized
    end

    def define_to_json__optimized!
      sql = compile(to_json_object(attributes).as("object"))

      ruby = <<-RUBY
      private def to_json__optimized(**)
        sql = wrap_aggregate(query.select(Arel.sql(#{sql.inspect})))
        query.connection.select_value(sql)
      end
      RUBY
      # puts "\e[34m#{ruby}\e[0m" # <-- helps debugging PluckMapPresenter
      class_eval ruby, __FILE__, __LINE__ - ruby.length
    end

    def to_json_object(attributes)
      args = []
      attributes.each do |attribute|
        args << Arel::Nodes::Quoted.new(attribute.name)
        args << send(:"prepare_#{attribute.class.name.gsub("::", "_")}", attribute)
      end
      PluckMap::BuildJsonObject.new(*args)
    end

    def prepare_PluckMap_Attribute(attribute)
      return Arel::Nodes::Quoted.new(attribute.value) if attribute.value?
      arg = attribute.selects[0]
      arg = attribute.model.arel_table[arg] if arg.is_a?(Symbol)
      arg
    end

    def prepare_PluckMap_StructuredAttribute(attribute)
      to_json_object(attribute.attributes)
    end

    def prepare_PluckMap_Relationships_Many(attribute)
      PluckMap::JsonSubqueryAggregate.new(attribute.scope, to_json_object(attribute.attributes))
    end

    def prepare_PluckMap_Relationships_One(attribute)
      Arel.sql("(#{attribute.scope.select(to_json_object(attribute.attributes)).to_sql})")
    end

    def wrap_aggregate(subquery)
      "SELECT #{compile(aggregate(Arel.sql("d.object")))} FROM (#{subquery.to_sql}) AS d"
    end

    def aggregate(object)
      PluckMap::JsonArrayAggregate.new(object)
    end

    def compile(node)
      visitor.compile(node)
    end

    def visitor
      model.connection.visitor
    end

    def default_json
      if defined?(MultiJson)
        MultiJson
      elsif defined?(Oj)
        Oj
      else
        JSON
      end
    end

  end
end
