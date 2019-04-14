require "json"

module PluckMap
  module JsonPresenter

    def to_json(query, json: default_json, **)
      if attributes.will_map?
        to_json__default(query, json: json)
      else
        to_json__optimized(query)
      end
    end

  private

    def to_json__default(query, json: default_json, **)
      json.dump(to_h(query))
    end

    def to_json__optimized(query, **)
      define_to_json__optimized!
      to_json__optimized(query)
    end

    def define_to_json__optimized!
      sql = compile(to_json_object(attributes).as("object"))

      ruby = <<-RUBY
      private def to_json__optimized(query, **)
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
        arg = attribute.selects[0]
        arg = attribute.model.arel_table[arg] if arg.is_a?(Symbol)
        args << arg
      end
      PluckMap::BuildJsonObject.new(*args)
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
