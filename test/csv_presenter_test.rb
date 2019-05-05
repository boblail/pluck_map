require "test_helper"

class CsvPresenterTest < Minitest::Test
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


  context "#to_csv" do
    should "pluck the identified fields from the database" do
      presenter = PluckMap[Person].define do
        first_name as: "Name, First"
        last_name as: "Name, Last"
      end

      assert_equal <<~TEXT, presenter.to_csv(authors)
        "Name, First","Name, Last"
        Graham,Greene
        Chiam,Potok
      TEXT
    end
  end

end
