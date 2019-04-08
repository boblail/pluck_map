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

  should "pluck attributes from the relation's table when joins make them ambiguous" do
    Book.create!(title: "The Chosen", author: authors.second)

    presenter = PluckMap::Presenter.new do
      id
    end

    authors_with_books = authors.joins("LEFT OUTER JOIN books ON books.author_id=authors.id")

    assert_equal [{ id: 1 }, { id: 2 }], presenter.to_h(authors_with_books)
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

  context "when :select is a SQL statement" do
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
