load File.expand_path("test_helper.rb", __dir__)
require "faker"
require "benchmark/ips"
require "benchmark/memory"

def define_benchmarks!(x)
  presenter = PluckMap[Author].define do
    id
    first_name
    last_name
  end

  pluck_json_sql = case ENV["ACTIVE_RECORD_ADAPTER"]
  when "mysql2"
    <<~SQL
      SELECT json_arrayagg(d.object) FROM (
        SELECT json_object(
          'id', authors.id,
          'first_name', authors.first_name,
          'last_name', authors.last_name
        ) AS object
        FROM authors
        ORDER BY authors.last_name ASC
      ) AS d
    SQL
  when "postgresql"
    <<~SQL
      SELECT json_agg(d.object) FROM (
        SELECT json_build_object(
          'id', authors.id,
          'first_name', authors.first_name,
          'last_name', authors.last_name
        ) AS object
        FROM authors
        ORDER BY authors.last_name ASC
      ) AS d
    SQL
  else # sqlite3
    <<~SQL
      SELECT json_group_array(json(d.object)) FROM (
        SELECT json_object(
          'id', authors.id,
          'first_name', authors.first_name,
          'last_name', authors.last_name
        ) AS object
        FROM authors
        ORDER BY authors.last_name ASC
      ) AS d
    SQL
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
    presenter.send(:to_json__default, Author.order(:last_name))
  end

  x.report("Pluck Json") do
    Author.connection.select_value(pluck_json_sql)
  end

  x.report("to_json__optimized") do
    presenter.send(:to_json__optimized, Author.order(:last_name))
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
