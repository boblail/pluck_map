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
    presenter = PluckMap[Author].define do
      last_name
    end

    assert_equal [
      { last_name: "Greene" },
      { last_name: "Potok" }
    ], presenter.to_h(authors)
  end

  should "pluck attributes from the relation's table when joins make them ambiguous" do
    Book.create!(title: "The Chosen", author: authors.second)

    presenter = PluckMap[Author].define do
      id
    end

    authors_with_books = authors.joins("LEFT OUTER JOIN books ON books.author_id=authors.id")

    assert_equal [{ id: 1 }, { id: 2 }], presenter.to_h(authors_with_books)
  end

  context "when :value is given" do
    should "present the value statically for each result" do
      presenter = PluckMap[Author].define do
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
      presenter = PluckMap[Author].define do
        last_name as: :lastName
      end

      assert_equal [
        { lastName: "Greene" },
        { lastName: "Potok" }
      ], presenter.to_h(authors)
    end

    context "and it contains spaces" do
      should "still work" do
        presenter = PluckMap[Author].define do
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
      presenter = PluckMap[Author].define do
        name select: Arel.sql("first_name || ' ' || last_name")
      end

      assert_equal [
        { name: "Graham Greene" },
        { name: "Chiam Potok" }
      ], presenter.to_h(authors)
    end

    should "correctly cast types when using the same SQL function multiple times" do
      presenter = PluckMap[Author].define do
        last_name select: Arel.sql("COALESCE(NULL, last_name)")
        id select: Arel.sql("COALESCE(NULL, id)")
      end

      assert_equal [
        { last_name: "Greene", id: authors.find_by(last_name: "Greene").id },
        { last_name: "Potok", id: authors.find_by(last_name: "Potok").id }
      ], presenter.to_h(authors)
    end
  end

  context "when :map is given" do
    should "yields the selected values to map" do
      presenter = PluckMap[Author].define do
        name select: %i{ first_name last_name }, map: ->(first, last) { "#{first} #{last}" }
      end

      assert_equal [
        { name: "Graham Greene" },
        { name: "Chiam Potok" }
      ], presenter.to_h(authors)
    end
  end

  context "when a value is selected more than once" do
    should "associate the right values with the right attributes" do
      presenter = PluckMap[Author].define do
        first select: :first_name
        last select: :last_name
        full select: %i{ first_name last_name }, map: ->(first, last) { "#{first} #{last}" }
      end

      mock.proxy(authors).pluck(:first_name, :last_name)

      assert_equal [
        { first: "Graham", last: "Greene", full: "Graham Greene" },
        { first: "Chiam", last: "Potok", full: "Chiam Potok" }
      ], presenter.to_h(authors)
    end
  end

end
