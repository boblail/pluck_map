require "test_helper"

class StructTest < Minitest::Test
  attr_reader :authors

  def setup
    DatabaseCleaner.start
    Person.create!([
      { first_name: "Graham", last_name: "Greene" },
      { first_name: "Chiam", last_name: "Potok" }
    ])
    @authors = Person.order(:last_name)
  end

  def teardown
    DatabaseCleaner.clean
  end

  context "presenter::Struct" do
    setup do
      @presenter = PluckMap[Person].define do
        first_name
        last_name
      end
    end

    should "be a struct" do
      assert @presenter::Struct.ancestors.include?(Struct)
    end

    should "differ from another presenter's struct" do
      another = PluckMap[Book].define do
        title
      end

      refute_equal @presenter::Struct.members, another::Struct.members
      refute_equal @presenter::Struct.presenter, another::Struct.presenter
    end

    context ".members" do
      should "correspond to the values being plucked" do
        assert_equal %i{ first_name last_name }, @presenter::Struct.members
      end
    end

    context ".load" do
      should "pluck the results to instances of presenter::Struct" do
        assert_equal [
          @presenter::Struct.new(first_name: "Graham", last_name: "Greene"),
          @presenter::Struct.new(first_name: "Chiam", last_name: "Potok")
        ], @presenter::Struct.load(authors)
      end

      should "pluck the results to instances of subclasses of presenter::Struct" do
        subclass = Class.new(@presenter::Struct)

        assert_equal [
          subclass.new(first_name: "Graham", last_name: "Greene"),
          subclass.new(first_name: "Chiam", last_name: "Potok")
        ], subclass.load(authors)
      end

      should "pluck the results to instances of grandchildren of presenter::Struct" do
        subclass = Class.new(@presenter::Struct)
        grandchild = Class.new(subclass)

        assert_equal [
          grandchild.new(first_name: "Graham", last_name: "Greene"),
          grandchild.new(first_name: "Chiam", last_name: "Potok")
        ], grandchild.load(authors)
      end
    end
  end

end
