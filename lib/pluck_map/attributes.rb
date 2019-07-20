module PluckMap
  class Attributes
    include Enumerable

    attr_reader :selects, :model

    def initialize(attributes, model)
      @model = model
      @_attributes = attributes.freeze
      @_attributes_by_id = {}
      @selects = []
      attributes.each do |attribute|
        attribute.indexes = attribute.selects.map do |select|
          selects.find_index(select) || begin
            selects.push(select)
            selects.length - 1
          end
        end
        _attributes_by_id[attribute.id] = attribute
      end
      _attributes_by_id.freeze
    end



    def each(&block)
      _attributes.each(&block)
    end

    def [](index)
      _attributes[index]
    end

    def length
      _attributes.length
    end



    def ids
      _attributes_by_id.keys
    end

    def by_id
      _attributes_by_id
    end

    def to_json_array
      PluckMap::BuildJsonArray.new(*selects.map do |select|
        select = model.arel_table[select] if select.is_a?(Symbol)
        select
      end)
    end



    def will_map?
      _attributes.any?(&:will_map?)
    end

    def nested?
      _attributes.any?(&:nested?)
    end



    def ==(other)
      return false if self.class != other.class
      _attributes == other.send(:_attributes)
    end

    def hash
      _attributes.hash
    end

    def eql?(other)
      return true if self.equal?(other)
      return false if self.class != other.class
      _attributes.eql?(other.send(:_attributes))
    end

  private
    attr_reader :_attributes, :_attributes_by_id
  end
end
