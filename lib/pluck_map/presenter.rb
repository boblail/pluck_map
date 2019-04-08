require "pluck_map/attribute_builder"

module PluckMap
  class Presenter
    attr_reader :attributes

    def initialize(&block)
      @attributes = PluckMap::AttributeBuilder.build(&block)
      @attributes_by_id = attributes.index_by(&:id).with_indifferent_access
      @selects = attributes.flat_map(&:selects).uniq

      define_presenters!
    end

    def no_map?
      attributes.all?(&:no_map?)
    end

  protected

    def define_presenters!
      define_to_h!
    end

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
    attr_reader :attributes_by_id, :selects

    def invoke(attribute_id, object)
      attributes_by_id.fetch(attribute_id).apply(object)
    end

    def define_to_h!
      ruby = <<-RUBY
      def to_h(query)
        pluck(query) do |results|
          results.map { |values| values = Array(values); { #{attributes.map { |attribute| "#{attribute.name.inspect} => #{attribute.to_ruby(selects)}"}.join(", ")} } }
        end
      end
      RUBY
      # puts "\e[34m#{ruby}\e[0m" # <-- helps debugging PluckMapPresenter
      class_eval ruby, __FILE__, __LINE__ - 7
    end

    def keys
      puts "DEPRECATION WARNING: PluckMap::Presenter#keys is deprecated; use #selects instead"
      selects
    end

  end
end
