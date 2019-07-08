# frozen_string_literal: true

class HearingsForDayQuery

  def initialize(day:)
    @day = day
  end

  def call
    days = HearingDay.where(scheduled_for: @day)

    fail ActiveRecord::RecordNotFound unless days.any?

    days_ids = days.map { |day| day.id }
    hearings = Hearing.where(hearing_day_id: days_ids)
    legacy_hearings = HearingRepository.fetch_hearings_for_parents(days_ids).values.flatten

    hearings + legacy_hearings
  end
end
