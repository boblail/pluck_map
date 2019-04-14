require "pluck_map/version"
require "pluck_map/presenter"
require "pluck_map/null_logger"

module PluckMap
  class << self
    attr_accessor :logger
  end

  @logger = defined?(Rails) ? Rails.logger : PluckMap::NullLogger.new
end
