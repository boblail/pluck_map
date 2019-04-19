require "test_helper"

class JsonPresenterTest < Minitest::Test
  attr_reader :presenter, :authors, :books

  def setup
    DatabaseCleaner.start
    Person.create!([
      { first_name: "Graham", last_name: "Greene" },
      { first_name: "Chiam", last_name: "Potok" }
    ])
    @authors = Person.order(:last_name)

    greene, potok = authors.pluck(:id)
    Book.create!([
      { author_id: greene, author_type: "Person", title: "The Tenth Man" },
      { author_id: greene, author_type: "Person", title: "The Power and the Glory" },
      { author_id: potok, author_type: "Person", title: "The Chosen" },
      { author_id: potok, author_type: "Person", title: "My Name is Asher Lev" }
    ])
    @books = Book.order(title: :desc)
  end

  def teardown
    DatabaseCleaner.clean
  end


  context "#to_json" do
    should "present the requested fields" do
      presenter = PluckMap[Person].define do
        last_name
      end

      assert_json_equal <<~JSON, presenter.to_json(authors)
      [
        { "last_name": "Greene" },
        { "last_name": "Potok" }
      ]
      JSON
    end
  end

  %i{ to_json__default to_json__optimized }.each do |method|
    context "##{method}" do
      should "present the requested fields" do
        presenter = PluckMap[Person].define do
          last_name
        end

        assert_json_equal <<~JSON, presenter.send(method, authors)
        [
          { "last_name": "Greene" },
          { "last_name": "Potok" }
        ]
        JSON
      end

      context "with has_many:" do
        setup do
          @presenter = PluckMap[Person].define do
            last_name
            has_many :books do
              type "Novel"
              title
            end
          end

          Person.create!(first_name: "Evelyn", last_name: "Waugh")
        end

        should "present the requested fields" do
          assert_json_equal <<~JSON, presenter.send(method, authors)
          [
            { "last_name": "Greene",
              "books": [
                { "type": "Novel", "title": "The Power and the Glory" },
                { "type": "Novel", "title": "The Tenth Man" } ] },
            { "last_name": "Potok",
              "books": [
                { "type": "Novel", "title": "My Name is Asher Lev" },
                { "type": "Novel", "title": "The Chosen" } ] },
            { "last_name": "Waugh",
              "books": [] }
          ]
          JSON
        end
      end

      context "with belongs_to:" do
        setup do
          @presenter = PluckMap[Book].define do
            has_one :author do
              name select: Arel.sql("first_name || ' ' || last_name")
            end
            title
          end

          Book.create!(title: "Animal Farm")
        end

        should "present the requested fields" do
          assert_json_equal <<~JSON, presenter.send(method, books)
          [
            { "author": { "name": "Graham Greene" }, "title": "The Tenth Man" },
            { "author": { "name": "Graham Greene" }, "title": "The Power and the Glory" },
            { "author": { "name": "Chiam Potok" }, "title": "The Chosen" },
            { "author": { "name": "Chiam Potok" }, "title": "My Name is Asher Lev" },
            { "author": null, "title": "Animal Farm" }
          ]
          JSON
        end
      end

      context "with has_one:" do
        setup do
          @presenter = PluckMap[Book].define do
            title
            has_one :isbn do
              number
            end
          end

          Book.find_by(title: "The Tenth Man").create_isbn!(number: "978-0671507947")
          Book.find_by(title: "The Power and the Glory").create_isbn!(number: "978-9994715640")
        end

        should "yield the selected values to map" do
          assert_json_equal <<~JSON, presenter.send(method, books)
          [
            { "title": "The Tenth Man", "isbn": { "number": "978-0671507947" } },
            { "title": "The Power and the Glory", "isbn": { "number": "978-9994715640" } },
            { "title": "The Chosen", "isbn": null },
            { "title": "My Name is Asher Lev", "isbn": null }
          ]
          JSON
        end
      end
    end
  end

private

  def assert_json_equal(a, b, *args)
    assert_equal normalize(a), normalize(b), *args
  end

  def normalize(json)
    JSON.dump(JSON.parse(json).map { |attributes| attributes.sort.to_h })
  end

end
