require "pluck_map/attribute_builder"
require "pluck_map/presenters"

module PluckMap
  class Presenter
    include CsvPresenter, HashPresenter, JsonPresenter

    attr_reader :attributes

    def initialize(&block)
      @attributes = PluckMap::AttributeBuilder.build(&block)

      if respond_to?(:define_presenters!, true)
        puts "DEPRECATION WARNING: `define_presenters!` is deprecated; instead mix in a module that implements your presenter method (e.g. `to_h`). Optionally have the method redefine itself the first time it is called."
        # because overridden `define_presenters!` will probably call `super`
        PluckMap::Presenter.class_eval 'protected def define_presenters!; end'
        define_presenters!
      end
    end

    def no_map?
      attributes.all?(&:no_map?)
    end

  protected

    def pluck(query)
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
      attributes.selects
    end

    def attributes_by_id
      attributes.by_id
    end

    def keys
      puts "DEPRECATION WARNING: PluckMap::Presenter#keys is deprecated with no replacement"
      selects
    end

  end
end
