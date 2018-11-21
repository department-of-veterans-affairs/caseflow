module HearingConcern
  extend ActiveSupport::Concern

  def request_type
    (type != Hearing::CO_HEARING) ? type.to_s.capitalize : "Central"
  end
end
