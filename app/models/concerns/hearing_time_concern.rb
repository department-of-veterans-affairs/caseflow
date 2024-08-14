# frozen_string_literal: true

module HearingTimeConcern
  extend ActiveSupport::Concern

  delegate :central_office_time_string, :scheduled_time_string,
           to: :time

  # Set the @time instance variable to
  # HearingDatetimeService instance if use_hearing_datetime? is true, else
  # to HearingTimeService instance
  def time
    @time ||= if use_hearing_datetime?
                HearingDatetimeService.new(hearing: self)
              else
                HearingTimeService.new(hearing: self)
              end
  end
end
