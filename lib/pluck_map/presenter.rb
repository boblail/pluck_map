require "pluck_map/version"
require "pluck_map/attribute"
require "pluck_map/null_logger"

module PluckMap
  class Presenter
    attr_reader :attributes

    @logger = defined?(Rails) ? Rails.logger : PluckMap::NullLogger.new
    class << self
      attr_accessor :logger
    end

    def initialize(&block)
      @attributes = []
      if block.arity == 1
        block.call(self)
      else
        instance_eval(&block)
      end
      @initialized = true

      @attributes_by_id = attributes.index_by(&:id).with_indifferent_access
      @keys = attributes.flat_map(&:keys).uniq

      define_presenters!
    end

    def method_missing(attribute_name, *args, &block)
      return super if initialized?
      options = args.extract_options!
      options[:value] = args.first unless args.empty?
      attributes.push PluckMap::Attribute.new(attribute_name, options)
      :attribute_added
    end

    def no_map?
      attributes.all?(&:no_map?)
    end

  protected

    def define_presenters!
      define_to_h!
    end

    def initialized?
      @initialized
    end

    def pluck(query)
      # puts "\e[95m#{query.select(*selects(query.table_name)).to_sql}\e[0m"
      results = benchmark("pluck(#{query.table_name})") { query.pluck(*selects(query.table_name)) }
      return results unless block_given?
      benchmark("map(#{query.table_name})") { yield results }
    end

    def benchmark(title)
      result = nil
      ms = Benchmark.ms { result = yield }
      self.class.logger.info "\e[33m#{title}: \e[1m%.1fms\e[0m" % ms
      result
    end

  private
    attr_reader :attributes_by_id, :keys

    def selects(table_name)
      attributes.flat_map do |attribute|
        if attribute.selects.length != 1
          attribute.selects
        else
          select = attribute.selects[0]
          select = "\"#{table_name}\".\"#{select}\"" if select.is_a?(Symbol)
          "#{select} AS \"#{attribute.alias}\""
        end
      end.uniq
    end

    def invoke(attribute_id, object)
      attributes_by_id.fetch(attribute_id).apply(object)
    end

    def define_to_h!
      ruby = <<-RUBY
      def to_h(query)
        pluck(query) do |results|
          results.map { |values| values = Array(values); { #{attributes.map { |attribute| "#{attribute.name.inspect} => #{attribute.to_ruby(keys)}"}.join(", ")} } }
        end
      end
      RUBY
      # puts "\e[34m#{ruby}\e[0m" # <-- helps debugging PluckMapPresenter
      class_eval ruby, __FILE__, __LINE__ - 7
    end

  end
end
