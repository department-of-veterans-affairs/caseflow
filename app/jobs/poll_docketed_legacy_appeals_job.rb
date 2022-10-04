# frozen_string_literal: true

# Active Job that handles polling VACOLS for legacy appeals that have been recently docketed

class PollDocketedLegacyAppealsJob < CaseflowJob
  queue_as :low_priority
  application_attr :hearing_schedule

  def perform
    most_recent_docketed_appeals(claim_histories)
  end

  # Purpose: To get a list of claim location histories to be used to get the date for docketing
  # Return: An array of case location history records
  def claim_histories
    vacols_appeals = VACOLS::CaseDocket.where(bfmpro: "ACT", bfac: %w[1 3 7])
    VACOLS::Priorloc.where(lockey: vacols_appeals.pluck(:bfkey), locstto: "01")
  end

  # Purpose: To get a list of all vacols ids for the most recent docketed appeals to be used for sending notifications
  # Params: claim_histories - An array of case location history records
  # Return: An array of vacols ids
  def most_recent_docketed_appeals(claim_histories)
    vacols_ids = []
    claim_histories.each do |claim_history|
      if Time.zone.today.strftime("%d").to_i - claim_history.locdout.strftime("%d").to_i < 1
        vacols_ids.push(claim_history.lockey)
      end
    end
    vacols_ids
  end
end
