# frozen_string_literal: true

##
# Determines the hearing day request type for multiple video hearing days.
#
# This class exists to optimize the process for determining the request
# type for multiple hearing days. Otherwise, you need to get a full list of
# the hearings for that day.

class VideoHearingDayRequestTypeQuery
  def initialize(hearing_days = HearingDay.all)
    @hearing_days = hearing_days
  end

  # Returns a hash of hearing day id to request type.
  def call
    (counts_for_ama_hearings + counts_for_legacy_hearings)
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

  private

  VIRTUAL_HEARINGS_COUNT_STATEMENT = <<-SQL
    count(
      case when virtual_hearings.status != 'cancelled'
        then true
      end
    ) as virtual_hearings_count
  SQL

  def counts_for_ama_hearings
    @hearing_days
      .where(request_type: VirtualHearing::VALID_REQUEST_TYPES)
      .joins("INNER JOIN hearings ON hearing_days.id = hearings.hearing_day_id")
      .joins(<<-SQL)
        LEFT OUTER JOIN virtual_hearings
        ON virtual_hearings.hearing_id = hearings.id
        AND virtual_hearings.hearing_type = 'Hearing'
        AND virtual_hearings.status != 'cancelled'
        AND NOT virtual_hearings.conference_deleted
      SQL
      .group(:id)
      .select(
        "id",
        "request_type",
        VIRTUAL_HEARINGS_COUNT_STATEMENT,
        "count(hearings.id) as hearings_count"
      )
  end

  def counts_for_legacy_hearings
    @hearing_days
      .where(request_type: VirtualHearing::VALID_REQUEST_TYPES)
      .joins("INNER JOIN legacy_hearings ON hearing_days.id = legacy_hearings.hearing_day_id")
      .joins(<<-SQL)
        LEFT OUTER JOIN virtual_hearings
        ON virtual_hearings.hearing_id = legacy_hearings.id
        AND virtual_hearings.hearing_type = 'LegacyHearing'
        AND virtual_hearings.status != 'cancelled'
        AND NOT virtual_hearings.conference_deleted
      SQL
      .group(:id)
      .select(
        "id",
        "request_type",
        VIRTUAL_HEARINGS_COUNT_STATEMENT,
        "count(legacy_hearings.id) as hearings_count"
      )
  end
end
