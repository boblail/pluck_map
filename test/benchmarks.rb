require_relative "test_helper"
require "faker"
require "benchmark/ips"
require "benchmark/memory"
require "database_cleaner"

adapter = ENV.fetch("ACTIVE_RECORD_ADAPTER", "sqlite3")
database = adapter == "sqlite3" ? ":memory:" : "pluck_map_test"

ActiveRecord::Base.establish_connection(
  adapter: adapter,
  host: "localhost",
  database: database,
  verbosity: "quiet")

load File.join(File.dirname(__FILE__), "support", "schema.rb")

def define_benchmarks!(x)
  presenter = PluckMap::Presenter.new do
    id
    first_name
    last_name
  end

  x.report("ActiveRecord") do
    JSON.dump(Author.order(:last_name).map { |author| {
      id: author.id,
      first_name: author.first_name,
      last_name: author.last_name
    } })
  end

  x.report("Pluck/Map Pattern") do
    JSON.dump(Author.order(:last_name)
      .pluck(:id, :first_name, :last_name)
      .map { |id, first_name, last_name| {
        id: id,
        first_name: first_name,
        last_name: last_name
    } })
  end

  x.report("PluckMap") do
    presenter.to_json(Author.order(:last_name))
  end
end



DatabaseCleaner.start

Author.create!(100.times.map { {
  first_name: Faker::Name.first_name,
  last_name: Faker::Name.last_name
} })

Author.uncached do
  Benchmark.ips do |x|
    define_benchmarks!(x)
    x.compare!
  end

  Benchmark.memory do |x|
    define_benchmarks!(x)
    x.compare!
  end
end

DatabaseCleaner.clean
