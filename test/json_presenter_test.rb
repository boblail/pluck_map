require "test_helper"

class JsonPresenterTest < Minitest::Test
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

    assert_equal JSON.dump([
      { last_name: "Greene" },
      { last_name: "Potok" }
    ]), normalize(presenter.to_json(authors))
  end


private

  def normalize(json)
    JSON.dump(JSON.parse(json))
  end

end
