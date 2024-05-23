# frozen_string_literal: true

class ExternalApi::WebexService::RecordingsListResponse < ExternalApi::WebexService::Response
  def recordings
    return [] if data["items"].blank?

    data["items"].map { |item| Recording.new(item["id"], item["host_email"]) }
  end

  class Recording
    attr_reader :id, :host_email

    def initialize(id, host_email)
      @id = id
      @host_email = host_email
    end
  end
end
