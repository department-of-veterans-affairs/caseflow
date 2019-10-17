# frozen_string_literal: true

class VirtualHearingRepository
  class << self
    def ready_for_deletion
      virtual_hearings_for_ama_hearings = VirtualHearing.eligible_for_deletion
          .where(hearing_type: Hearing.name)
          .joins("INNER JOIN hearings ON hearings.id = virtual_hearings.hearing_id")
          .joins("INNER JOIN hearing_days ON hearing_days.id = hearings.hearing_day_id")
          .where("hearing_days.scheduled_for < :today", today: Date.today)

      # Get all VACOLS ids for legacy hearings with a virtual hearing that
      # is eligible for deletion.
      vacols_ids_for_eligible_virtual_hearings = VirtualHearing.eligible_for_deletion
        .where(hearing_type: LegacyHearing.name)
        .joins("INNER JOIN legacy_hearings ON legacy_hearings.id = virtual_hearings.hearing_id")
        .pluck("legacy_hearings.vacols_id")
        .to_a

      # Query VACOLS for all hearings that are before today and that match an ID
      # in the list of legacy hearings with a virtual hearing eligible for deletion.
      legacy_hearings_before_today = VACOLS::CaseHearing
          .where(hearing_pkseq: vacols_ids_for_eligible_virtual_hearings)
          .where("hearing_date < :today", today: Date.today)
          .select(:hearing_pkseq)
          .to_a

      virtual_hearings_for_legacy_hearings = VirtualHearing.eligible_for_deletion
        .where(hearing_type: LegacyHearing.name)
        .joins("INNER JOIN legacy_hearings ON legacy_hearings.id = virtual_hearings.hearing_id")
        .where("legacy_hearings.vacols_id": legacy_hearings_before_today)

      virtual_hearings_for_ama_hearings + virtual_hearings_for_legacy_hearings
    end
  end
end
