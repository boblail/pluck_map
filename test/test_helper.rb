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

adapter = ENV.fetch("ACTIVE_RECORD_ADAPTER", "sqlite3")
database = adapter == "sqlite3" ? ":memory:" : "pluck_map_test"

ActiveRecord::Base.establish_connection(
  adapter: adapter,
  host: "localhost",
  database: database,
  verbosity: "quiet")

load File.join(File.dirname(__FILE__), "support", "schema.rb")


# ============================================================================ #
# Patch for DatabaseCleaner which relies on `postgresql_version` which
# was renamed to `database_version` in Rails 6.
#
if defined?(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
  unless ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.instance_methods.member?(:postgresql_version)
    class ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
      alias_method :postgresql_version, :database_version
    end
  end
end
# ============================================================================ #


DatabaseCleaner.strategy = :truncation