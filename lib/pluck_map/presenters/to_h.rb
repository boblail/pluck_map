module PluckMap
  module HashPresenter

    def self.included(base)
      def base.to_h(query, **kargs)
        new(query).to_h(**kargs)
      end
    end

    def to_h
      define_to_h!
      to_h
    end

    private def define_to_h!
      ruby = <<-RUBY
      def to_h
        pluck do |results|
          results.map { |values| values = Array(values); { #{attributes.map { |attribute| "#{attribute.name.inspect} => #{attribute.to_ruby}" }.join(", ")} } }
        end
      end
      RUBY
      # puts "\e[34m#{ruby}\e[0m" # <-- helps debugging PluckMapPresenter
      class_eval ruby, __FILE__, __LINE__ - 7
    end

  end
end
