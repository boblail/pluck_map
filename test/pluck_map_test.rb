require "test_helper"

class PluckMapTest < Minitest::Test
  attr_reader :authors

  def setup
    DatabaseCleaner.start
    Author.create!([
      { first_name: "Graham", last_name: "Greene" },
      { first_name: "Chiam", last_name: "Potok" }
    ])
    @authors = Author.order(:last_name)
  end

  def teardown
    DatabaseCleaner.clean
  end


  should "pluck the identified fields for a model from the database" do
    presenter = PluckMap::Presenter.new do
      last_name
    end

    assert_equal [
      { last_name: "Greene" },
      { last_name: "Potok" }
    ], presenter.to_h(authors)
  end

  context "when :value is given" do
    should "present the value statically for each result" do
      presenter = PluckMap::Presenter.new do
        type value: "Author"
        last_name
      end

      assert_equal [
        { type: "Author", last_name: "Greene" },
        { type: "Author", last_name: "Potok" }
      ], presenter.to_h(authors)
    end

    context "and it is falsey" do
      should "present the value statically for each result" do
        presenter = PluckMap::Presenter.new do
          living value: false
          last_name
        end

        assert_equal [
          { living: false, last_name: "Greene" },
          { living: false, last_name: "Potok" }
        ], presenter.to_h(authors)
      end
    end
  end

  context "when :as is given" do
    should "present the plucked value with the specified key" do
      presenter = PluckMap::Presenter.new do
        last_name as: :lastName
      end

      assert_equal [
        { lastName: "Greene" },
        { lastName: "Potok" }
      ], presenter.to_h(authors)
    end

    context "and it contains spaces" do
      should "still work" do
        presenter = PluckMap::Presenter.new do
          last_name as: "Last Name"
        end

        assert_equal [
          { "Last Name" => "Greene" },
          { "Last Name" => "Potok" }
        ], presenter.to_h(authors)
      end
    end
  end

  context "when :select is given" do
    should "pull the values from the specified column" do
      presenter = PluckMap::Presenter.new do
        lastName select: :last_name
      end

      assert_equal [
        { lastName: "Greene" },
        { lastName: "Potok" }
      ], presenter.to_h(authors)
    end

    context "and it is a SQL statement" do
      should "calculate the values using the specified expression" do
        concat_sql = if Author.connection_config[:adapter] == "mysql2"
          Arel.sql("CONCAT(first_name, ' ', last_name)")
        else
          Arel.sql("first_name || ' ' || last_name")
        end

        presenter = PluckMap::Presenter.new do
          name select: concat_sql
        end

        assert_equal [
          { name: "Graham Greene" },
          { name: "Chiam Potok" }
        ], presenter.to_h(authors)
      end
    end
  end

  context "when :map is given" do
    should "yields the selected values to map" do
      presenter = PluckMap::Presenter.new do
        name select: %i{ first_name last_name }, map: ->(first, last) { "#{first} #{last}" }
      end

      assert_equal [
        { name: "Graham Greene" },
        { name: "Chiam Potok" }
      ], presenter.to_h(authors)
    end
  end

end
