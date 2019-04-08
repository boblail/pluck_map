module PluckMap
  class Attribute
    attr_reader :id, :selects, :name, :block
    alias keys selects

    def initialize(id, options={})
      @id = id
      @selects = Array(options.fetch(:select, id))
      @name = options.fetch(:as, id)
      @block = options[:map]

      if options.key? :value
        @value = options[:value]
        @selects = []
      else
        raise ArgumentError, "You must select at least one column" if selects.empty?
        raise ArgumentError, "You must define a block if you are going to select " <<
          "more than one expression from the database" if selects.length > 1 && !block
      end
    end

    def apply(object)
      block.call(*object)
    end

    def no_map?
      block.nil?
    end

    # When the PluckMapPresenter performs the query, it will
    # receive an array of rows. Each row will itself be an
    # array of values.
    #
    # This method constructs a Ruby expression that will
    # extract the appropriate values from each row that
    # correspond to this Attribute.
    #
    # The array of values will be correspond to the array
    # of keys. This method determines which values pertain
    # to it by figuring out which order its keys were selected in
    def to_ruby(keys)
      return @value.inspect if defined?(@value)
      indexes = self.keys.map { |key| keys.index(key) }
      return "values[#{indexes[0]}]" if indexes.length == 1 && !block
      ruby = "values.values_at(#{indexes.join(", ")})"
      ruby = "invoke(:\"#{id}\", #{ruby})" if block
      ruby
    end
  end
end
