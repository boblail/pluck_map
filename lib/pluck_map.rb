require "pluck_map/version"
require "pluck_map/presenter"
require "pluck_map/null_logger"

module PluckMap
  class << self
    attr_accessor :logger
  end

  @logger = (Rails.logger if defined?(Rails)) || PluckMap::NullLogger.new
end
