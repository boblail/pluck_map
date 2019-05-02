require "pluck_map/version"
require "pluck_map/model_context"
require "pluck_map/presenter"
require "pluck_map/null_logger"

module PluckMap
  class << self
    attr_accessor :logger

    def [](model)
      PluckMap::ModelContext.new(model)
    end
  end

  @logger = (Rails.logger if defined?(Rails)) || PluckMap::NullLogger.new
end
