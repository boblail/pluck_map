require "test_helper"

class RelationshipsTest < Minitest::Test
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

  context "has_many:" do
    setup do
      greene, potok = authors.pluck(:id)
      Book.create!([
        { author_id: greene, author_type: "Person", title: "The Tenth Man" },
        { author_id: greene, author_type: "Person", title: "The Power and the Glory" },
        { author_id: potok, author_type: "Person", title: "The Chosen" },
        { author_id: potok, author_type: "Person", title: "My Name is Asher Lev" },

        # Should exclude this record because person.books is polymorphic
        { author_id: greene, author_type: "Character", title: "The Life and Lies of ... Dumbledore" }
      ])
    end

    should "yield the selected values to map" do
      presenter = PluckMap[Person].define do
        last_name as: :by
        has_many :books, as: :novels do
          title
        end
      end

      assert_equal [
        { by: "Greene", novels: [
          { title: "The Power and the Glory" },
          { title: "The Tenth Man" } ] },
        { by: "Potok", novels: [
          { title: "My Name is Asher Lev" },
          { title: "The Chosen" } ] }
      ], presenter.to_h(authors)
    end
  end

  context "belongs_to:" do
    setup do
      greene, potok = authors.pluck(:id)
      Book.create!([
        { author_id: greene, author_type: "Person", title: "The Tenth Man" },
        { author_id: greene, author_type: "Person", title: "The Power and the Glory" },
        { author_id: potok, author_type: "Person", title: "The Chosen" },
        { author_id: potok, author_type: "Person", title: "My Name is Asher Lev" }
      ])
    end

    should "yield the selected values to map" do
      presenter = PluckMap[Book].define do
        title
        has_one :author do
          name select: %i{ first_name last_name }, map: ->(*parts) { parts.join(" ") }
        end
      end

      assert_equal [
        { title: "The Tenth Man", author: { name: "Graham Greene" } },
        { title: "The Power and the Glory", author: { name: "Graham Greene" } },
        { title: "The Chosen", author: { name: "Chiam Potok" } },
        { title: "My Name is Asher Lev", author: { name: "Chiam Potok" } }
      ], presenter.to_h(Book.order(title: :desc))
    end
  end

  context "belongs_to: (polymorphic)" do
    setup do
      rowling = Person.create!(first_name: "J.K.", last_name: "Rowling")
      skeeter = Character.create!(first_name: "Rita", last_name: "Skeeter")
      book = Book.create!(author_id: rowling.id, author_type: "Person", title: "Harry Potter and the Deathly Hallows")
      Book.create!(author_id: skeeter.id, author_type: "Character", title: "The Life and Lies of ... Dumbledore")
      book.characters << skeeter
    end

    should "yield the selected values to map" do
      presenter = PluckMap[RealOrFictionalBook].define do
        title
        has_one :author do
          name select: %i{ first_name last_name }, map: ->(*parts) { parts.join(" ") }
        end
      end

      assert_equal [
        { title: "Harry Potter and the Deathly Hallows", author: { name: "J.K. Rowling" } },
        { title: "The Life and Lies of ... Dumbledore", author: { name: "Rita Skeeter" } }
      ], presenter.to_h(RealOrFictionalBook.order(:title))
    end
  end

  context "has_one:" do
    setup do
      greene, potok = authors.pluck(:id)
      Book.create!([
        { author_id: greene, author_type: "Person", title: "The Tenth Man" },
        { author_id: greene, author_type: "Person", title: "The Power and the Glory" },
        { author_id: potok, author_type: "Person", title: "The Chosen" },
        { author_id: potok, author_type: "Person", title: "My Name is Asher Lev" }
      ])
      Book.find_by(title: "The Tenth Man").create_isbn!(number: "978-0671507947")
      Book.find_by(title: "The Power and the Glory").create_isbn!(number: "978-9994715640")
    end

    should "yield the selected values to map" do
      presenter = PluckMap[Book].define do
        title
        has_one :isbn do
          number
        end
      end

      assert_equal [
        { title: "The Tenth Man", isbn: { number: "978-0671507947" } },
        { title: "The Power and the Glory", isbn: { number: "978-9994715640" } },
        { title: "The Chosen", isbn: nil },
        { title: "My Name is Asher Lev", isbn: nil }
      ], presenter.to_h(Book.order(title: :desc))
    end
  end

  context "has_and_belongs_to_many:" do
    setup do
      books = Book.create!([
        { title: "Harry Potter and The Prisoner of Azkaban" },
        { title: "Harry Potter and The Order of The Phoenix" }
      ])
      characters = Character.create!([
        { first_name: "Nymphadora", last_name: "Tonks" },
        { first_name: "Remus", last_name: "Lupin" }
      ])
      books[0].characters << characters[1]
      books[1].characters << characters[1]
      books[1].characters << characters[0]
    end

    should "yield the selected values to map" do
      presenter = PluckMap[Book].define do
        title
        has_many :characters, -> { order(last_name: :asc) } do
          last_name
        end
      end

      assert_equal [
        { title: "Harry Potter and The Prisoner of Azkaban",
          characters: [{ last_name: "Lupin" }] },
        { title: "Harry Potter and The Order of The Phoenix",
          characters: [{ last_name: "Lupin" }, { last_name: "Tonks" }] }
      ], presenter.to_h(Book.all)
    end
  end

  context "has_many through:" do
    setup do
      greene, potok = authors.pluck(:id)
      books = Book.create!([
        { author_id: greene, author_type: "Person", title: "The Quiet American" },
        { author_id: potok, author_type: "Person", title: "The Chosen" }
      ])
      characters = Character.create!([
        { first_name: "Thomas", last_name: "Fowler" },
        { first_name: "Reuven", last_name: "Malter" },
        { first_name: "Danny", last_name: "Saunders" }
      ])
      books[0].characters << characters[0]
      books[1].characters << characters[1]
      books[1].characters << characters[2]
    end

    should "yield the selected values to map" do
      presenter = PluckMap[Person].define do
        last_name
        has_many :characters do
          last_name
        end
      end

      assert_equal [
        { last_name: "Greene", characters: [{ last_name: "Fowler" }] },
        { last_name: "Potok", characters: [{ last_name: "Malter" }, { last_name: "Saunders" }] }
      ], presenter.to_h(authors)
    end
  end

  context "with redundant paths to a record" do
    setup do
      # If an author uses the same characters in more than one book,
      # Rails' behavior for `Person#characters` is to return characters
      # more than once if there is more than one path to that character
      # (if that character shows up in more than one book).
      #
      # Whether this is the "right" behavior or not, I'm not sure, but
      # PluckMap will behave consistently with Rails for now and I'll
      # move the conversation there.
      skip
      greene, potok = authors.pluck(:id)
      book = Book.create!(author_id: potok, author_type: "Person", title: "The Promise")
      characters = Character.all.to_a
      book.characters << characters[1]
      book.characters << characters[2]
    end

    should "yield only unique values of characters" do
      presenter = PluckMap[Person].define do
        last_name
        has_many :characters do
          last_name
        end
      end

      assert_equal [
        { last_name: "Greene", characters: [{ last_name: "Fowler" }] },
        { last_name: "Potok", characters: [{ last_name: "Malter" }, { last_name: "Saunders" }] }
      ], presenter.to_h(authors)
    end
  end

end
