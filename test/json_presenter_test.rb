require "test_helper"

class JsonPresenterTest < Minitest::Test
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
