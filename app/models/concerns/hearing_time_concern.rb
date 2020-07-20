# frozen_string_literal: true

module HearingTimeConcern
  extend ActiveSupport::Concern

  delegate :central_office_time_string, :scheduled_time_string,
           to: :time

  def time
    @time ||= HearingTimeService.new(hearing: self)
  end
end
