# frozen_string_literal: true

##
# Determines the hearing day request type for multiple video or central hearing
# days.
#
# This class exists to optimize the process for determining the request
# type for multiple hearing days. Otherwise, you need to get a full list of
# the hearings for that day.

class HearingDayRequestTypeQuery
  attr_reader :hearing_days

  def initialize(hearing_days = HearingDay.all)
    @hearing_days = hearing_days
  end

  # Returns a hash of hearing day id to request type.
  def call
    (hearing_days.counts_for_ama_hearings + hearing_days.counts_for_legacy_hearings)
      .group_by(&:id)
      .transform_values! do |row|
        virtual_hearings_count = row.sum(&:virtual_hearings_count)
        hearings_count = row.sum(&:hearings_count)
        request_type = Hearing::HEARING_TYPES[row.first.request_type.to_sym]

        if virtual_hearings_count == 0
          request_type
        elsif virtual_hearings_count == hearings_count
          COPY::VIRTUAL_HEARING_REQUEST_TYPE
        else
          "#{request_type}, #{COPY::VIRTUAL_HEARING_REQUEST_TYPE}"
        end
      end
  end
end
