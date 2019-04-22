require "json"

module PluckMap
  module JsonPresenter

    def to_json(query, json: default_json, **)
      json.dump(to_h(query))
    end

  private

    def default_json
      if defined?(MultiJson)
        MultiJson
      elsif defined?(Oj)
        Oj
      else
        JSON
      end
    end

  end
end
