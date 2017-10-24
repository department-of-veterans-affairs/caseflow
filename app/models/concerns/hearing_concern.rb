module HearingConcern
  extend ActiveSupport::Concern

  def request_type
    type != :central_office ? type.to_s.capitalize : "CO"
  end
end
