require "rubygems"

require "minitest/reporters/turn_reporter"
MiniTest::Reporters.use! Minitest::Reporters::TurnReporter.new

require "database_cleaner"
require "pluck_map"
require "active_record"
require "shoulda/context"
require "support/author"
require "support/book"
require "minitest/autorun"
require "pry"

ActiveRecord::Base.establish_connection(
  adapter: "sqlite3",
  database: ":memory:",
  verbosity: "quiet")

load File.join(File.dirname(__FILE__), "support", "schema.rb")

DatabaseCleaner.strategy = :truncation
