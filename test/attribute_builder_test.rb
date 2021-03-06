require "test_helper"

class AttributeBuilderTest < Minitest::Test

  should "accept either a DSL-style block (no args) or a block that accepts the Builder object" do
    a = PluckMap::AttributeBuilder.build(model: Person) do
      last_name
    end

    b = PluckMap::AttributeBuilder.build(model: Person) do |builder|
      builder.last_name
    end

    assert_equal a, b
  end

  should "return an array of attributes for each declaration" do
    attributes = PluckMap::AttributeBuilder.build(model: Person) do
      first_name
      last_name
    end

    assert_equal 2, attributes.length
  end

  should "take the declaration as both the column to be selected and the value's name" do
    attributes = PluckMap::AttributeBuilder.build(model: Person) do
      last_name
    end

    assert_equal :last_name, attributes[0].name
    assert_equal %i{ last_name }, attributes[0].selects
  end

  should "allow overriding the selected attributes with select:" do
    attributes = PluckMap::AttributeBuilder.build(model: Person) do
      last_name select: :surname
    end

    assert_equal :last_name, attributes[0].name
    assert_equal %i{ surname }, attributes[0].selects
  end

  should "allow overriding the value's name with as:" do
    attributes = PluckMap::AttributeBuilder.build(model: Person) do
      last_name as: :lastName
    end

    assert_equal :lastName, attributes[0].name
    assert_equal %i{ last_name }, attributes[0].selects
  end

  should "allow select: to be specified as an array" do
    attributes = PluckMap::AttributeBuilder.build(model: Person) do
      last_name select: %i{ surname }
    end

    assert_equal :last_name, attributes[0].name
    assert_equal %i{ surname }, attributes[0].selects
  end

  should "prohibit an empty array for :select" do
    assert_raises ArgumentError do
      PluckMap::AttributeBuilder.build(model: Person) do
        name select: []
      end
    end
  end

  should "prohibit multiple selects for :select" do
    assert_raises ArgumentError do
      PluckMap::AttributeBuilder.build(model: Person) do
        name select: %i{ first_name last_name }
      end
    end
  end

  should "prohibit raw SQL for :select" do
    assert_raises ArgumentError do
      PluckMap::AttributeBuilder.build(model: Person) do
        name select: "first_name || ' ' || last_name"
      end
    end
  end

  should "accept Arel::Nodes::SqlLiteral :select" do
    PluckMap::AttributeBuilder.build(model: Person) do
      name select: Arel.sql("first_name || ' ' || last_name")
    end
  end

  should "coerce selects to an empty array of selects when value: is given" do
    attributes = PluckMap::AttributeBuilder.build(model: Person) do
      type value: "Person", selects: %i{ a b c }
    end

    assert_equal "Person", attributes[0].value
    assert_equal [], attributes[0].selects
  end

  should "allow value: to be falsey" do
    attributes = PluckMap::AttributeBuilder.build(model: Person) do
      living value: false
    end

    assert_equal false, attributes[0].value
  end

  should "allow multiple selects when map: is given" do
    attributes = PluckMap::AttributeBuilder.build(model: Person) do
      name select: %i{ first_name last_name }, map: ->(first, last) { "#{first} #{last}" }
    end

    assert_equal :name, attributes[0].name
    assert_equal %i{ first_name last_name }, attributes[0].selects
  end

  should "allow structured attributes" do
    attributes = PluckMap::AttributeBuilder.build(model: Book) do
      author do
        id select: :author_id
        type select: :author_type
      end
    end

    assert_equal :author, attributes[0].name
    assert_equal %i{ author_id author_type }, attributes[0].attributes.selects
  end

end
