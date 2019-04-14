module PluckMap
  module HashPresenter

    def to_h(query)
      define_to_h!
      to_h(query)
    end

    private def define_to_h!
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

  end
end
