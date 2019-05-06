require "test_helper"

class BackwardsCompatibilityTest < Minitest::Test

  context "Adding custom presenter methods via `define_presenters!`" do
    teardown do
      PluckMap::Presenter.undef_method :define_presenters!
    end

    should "still work" do
      klass = Class.new(PluckMap::Presenter) do
        def define_presenters!
          super
          define_for_json_api!
        end
      end

      mock.instance_of(klass).define_for_json_api!

      presenter = klass.new do
        last_name
      end

      presenter.to_h(Author.all)
    end
  end

  context "Selecting Raw SQL strings" do
    setup do
      DatabaseCleaner.start
      Author.create!([{ first_name: "Graham", last_name: "Greene" }])
    end

    teardown do
      DatabaseCleaner.clean
    end

    should "still work" do
      presenter = PluckMap[Author].define do
        name select: "first_name || ' ' || last_name"
      end

      assert_equal [{ name: "Graham Greene" }], presenter.to_h(Author.all)
    end
  end

end
