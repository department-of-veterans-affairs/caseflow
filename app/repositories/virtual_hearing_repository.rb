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

    def create_virtual_hearing_for_legacy_hearing(legacy_hearing)
      ActiveRecord::Base.multi_transaction do
        created_hearing = VirtualHearing.create!(hearing: legacy_hearing)

        HearingRepository.update_vacols_hearing!(legacy_hearing.vacols_record, { request_type: :R })

        created_hearing
      end
    end
  end
end
