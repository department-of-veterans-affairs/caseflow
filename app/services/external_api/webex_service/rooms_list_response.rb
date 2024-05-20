# frozen_string_literal: true

class ExternalApi::WebexService::RoomsListResponse < ExternalApi::WebexService::Response
  def rooms
    return [] if data["items"].blank?

    data["items"].map { |item| Room.new(item["id"], item["title"]) }
  end

  class Room
    attr_reader :id, :title

    def initialize(id, title)
      @id = id
      @title = title
    end
  end
end
