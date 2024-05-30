# frozen_string_literal: true

class ExternalApi::WebexService::RecordingsListResponse < ExternalApi::WebexService::Response
  def recordings
    return [] if data["items"].blank?

    data["items"].map { |item| Recording.new(item["id"], item["hostEmail"]) }
  end

  class Recording
    attr_reader :id, :host_email

    # rubocop:disable Naming/MethodParameterName, Naming/VariableName
    def initialize(id, hostEmail)
      @id = id
      @host_email = hostEmail
    end
    # rubocop:enable Naming/MethodParameterName, Naming/VariableName
  end
end
