require "pluck_map/attribute_builder"
require "pluck_map/presenters"

module PluckMap
  class Presenter
    include CsvPresenter, HashPresenter, JsonPresenter

    attr_reader :model, :attributes

    def initialize(model = nil, attributes = nil, &block)
      if block_given?
        puts "DEPRECATION WARNING: `PluckMap::Presenter.new` will be deprecated. Use `PluckMap[Model].define` instead."
        @attributes = PluckMap::AttributeBuilder.build(model: nil, &block)
      else
        @model = model
        @attributes = attributes
      end

      if respond_to?(:define_presenters!, true)
        puts "DEPRECATION WARNING: `define_presenters!` is deprecated; instead mix in a module that implements your presenter method (e.g. `to_h`). Optionally have the method redefine itself the first time it is called."
        # because overridden `define_presenters!` will probably call `super`
        PluckMap::Presenter.class_eval 'protected def define_presenters!; end'
        define_presenters!
      end
    end

    def no_map?
      puts "DEPRECATION WARNING: `PluckMap::Presenter#no_map?` is deprecated. You can replace it with `!attributes.will_map?`"
      !attributes.will_map?
    end

  protected

    def pluck(query)
      if model && query.model != model
        raise ArgumentError, "Query for #{query.model} but #{model} expected"
      end

      # puts "\e[95m#{query.select(*selects).to_sql}\e[0m"
      results = benchmark("pluck(#{query.table_name})") { query.pluck(*selects) }
      return results unless block_given?
      benchmark("map(#{query.table_name})") { yield results }
    end

    def benchmark(title)
      result = nil
      ms = Benchmark.ms { result = yield }
      PluckMap.logger.info "\e[33m#{title}: \e[1m%.1fms\e[0m" % ms
      result
    end

  private

    def invoke(attribute_id, object)
      attributes_by_id.fetch(attribute_id).apply(object)
    end

    def selects
      attributes.selects.map.with_index { |select, index|

        # Workaround for a bug that exists in Rails at the time of this commit.
        # See:
        #
        #    https://github.com/rails/rails/pull/36186
        #
        # Prior to the PR above, Rails will treat two results that have the
        # same name as having the same type. On Postgres, values that are the
        # result of an expression are given the name of the last function
        # called in the expression. For example:
        #
        #    psql> SELECT COALESCE(NULL, 'four'), COALESCE(NULL, 4);
        #     coalesce | coalesce
        #    ----------+----------
        #     four     |        4
        #    (1 row)
        #
        # This patch mitigates that problem by aliasing SQL expressions before
        # they are used in select statements.
        select = select.is_a?(Symbol) ? select : select.as("__pluckmap_#{index}")

        # On Rails 4.2, `pluck` can't accept Arel nodes
        select = Arel.sql(select.to_sql) if ActiveRecord.version.segments.take(2) == [4,2] && select.respond_to?(:to_sql)
        select
      }
    end

    def attributes_by_id
      attributes.by_id
    end

    def keys
      puts "DEPRECATION WARNING: PluckMap::Presenter#keys is deprecated; use #selects instead"
      selects
    end

  end
end
