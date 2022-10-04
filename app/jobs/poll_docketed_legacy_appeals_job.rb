# frozen_string_literal: true

# Purpose: Active Job that handles polling VACOLS for legacy appeals that have been recently docketed

class PollDocketedLegacyAppealsJob < CaseflowJob
  queue_as :low_priority
  application_attr :hearing_schedule

  def perform
    vacols_appeals = VACOLS::CaseDocket.where(bfmpro: "ACT", bfac: %w[1 3 7])
    claim_histories = VACOLS::Priorloc.where(lockey: vacols_appeals.pluck(:bfkey), locstto: "01")
    vacols_ids = []
    claim_histories.each do |claim_history|
      if Time.zone.today.strftime("%d").to_i - claim_history.locdout.strftime("%d").to_i < 1
        vacols_ids.push(claim_history.lockey)
      end
    end
    vacols_ids
  end
end
