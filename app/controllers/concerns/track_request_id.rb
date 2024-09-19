# frozen_string_literal: true

module TrackRequestId
  extend ActiveSupport::Concern

  included do
    before_action :track_request_id
  end

  def track_request_id
    ::NewRelic::Agent.add_custom_attributes(request_id: request.uuid)
  end
end
