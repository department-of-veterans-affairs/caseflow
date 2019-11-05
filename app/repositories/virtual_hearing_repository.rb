# frozen_string_literal: true

class VirtualHearingRepository
  class << self
    def ready_for_deletion
      virtual_hearings_for_ama_hearings = VirtualHearing.eligible_for_deletion
        .where(hearing_type: Hearing.name)
        .joins("INNER JOIN hearings ON hearings.id = virtual_hearings.hearing_id")
        .joins("INNER JOIN hearing_days ON hearing_days.id = hearings.hearing_day_id")
        .where("hearing_days.scheduled_for < :today", today: Time.zone.today)

      virtual_hearings_for_legacy_hearings = VirtualHearing.eligible_for_deletion
        .where(hearing_type: LegacyHearing.name)
        .joins("INNER JOIN legacy_hearings ON legacy_hearings.id = virtual_hearings.hearing_id")
        .joins("INNER JOIN hearing_days ON hearing_days.id = legacy_hearings.hearing_day_id")
        .where("hearing_days.scheduled_for < :today", today: Time.zone.today)

      virtual_hearings_for_ama_hearings + virtual_hearings_for_legacy_hearings
    end

    def hearing_day_has_virtual_hearing?(hearing_day)
      virtual_hearing_for_ama_hearing_exists = VirtualHearing
        .where(hearing_type: Hearing.name)
        .joins("INNER JOIN hearings ON hearings.id = virtual_hearings.hearing_id")
        .where("hearings.hearing_day_id = :hearing_day_id", hearing_day_id: hearing_day.id)
        .exists?

      # Small optimization: avoids a second query, if there is already an AMA hearing!
      return true if virtual_hearing_for_ama_hearing_exists

      virtual_hearing_for_legacy_hearing_exists = VirtualHearing
        .where(hearing_type: LegacyHearing.name)
        .joins("INNER JOIN legacy_hearings ON legacy_hearings.id = virtual_hearings.hearing_id")
        .where("legacy_hearings.hearing_day_id = :hearing_day_id", hearing_day_id: hearing_day.id)
        .exists?

      virtual_hearing_for_legacy_hearing_exists
    end
  end
end
