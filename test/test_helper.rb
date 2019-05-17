require "rubygems"

require "minitest/reporters/turn_reporter"
MiniTest::Reporters.use! Minitest::Reporters::TurnReporter.new

require "database_cleaner"
require "pluck_map"
require "active_record"
require "shoulda/context"
require_relative "support/author"
require_relative "support/book"
require_relative "support/novel"
require "minitest/autorun"
require "rr"
require "pry"

config = {
  adapter: ENV.fetch("ACTIVE_RECORD_ADAPTER", "sqlite3"),
  host: "localhost",
  database: "pluck_map_test",
  verbosity: "quiet"
}

case config[:adapter]
when "sqlite3"
  config[:database] = ":memory:"
when "mysql2"
  # Allows us to concatenate strings with pipes — `first_name || ' ' || last_name`
  config[:variables] = { sql_mode: "PIPES_AS_CONCAT" }
end

ActiveRecord::Base.establish_connection(config)

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
