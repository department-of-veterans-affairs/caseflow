# frozen_string_literal: true

# Active Job that handles polling VACOLS for legacy appeals that have been recently docketed

class PollDocketedLegacyAppealsJob < CaseflowJob
  queue_as :low_priority
  application_attr :hearing_schedule

  LEGACY_DOCKETED = "
    SELECT bfkey
    FROM brieff
    INNER JOIN priorloc
    ON brieff.bfkey = priorloc.lockey
    WHERE bfac IN ('1', '3', '7')
    AND locstto = '01'
    AND trunc(locdout) = trunc(sysdate)
  "

  def perform
    vacols_ids = most_recent_docketed_appeals(claim_histories)
    filtered_vacols_ids = filter_duplicate_legacy_notifications(vacols_ids)
    send_legacy_notifications(filtered_vacols_ids)
  end

  # Purpose: To get a list of claim location histories to be used to get the date for docketing
  # Return: An array of case location history records
  def claim_histories
    vacols_appeals = VACOLS::Case.where(bfmpro: "ACT", bfac: %w[1 3 7])
    VACOLS::Priorloc.where(lockey: vacols_appeals.pluck(:bfkey), locstto: "01")

    # sql = "SELECT bfkey FROM brieff INNER JOIN priorloc ON brieff.bfkey = priorloc.lockey WHERE bfac IN ('1', '3', '7') AND locstto = '01' AND trunc(locdout) = trunc(sysdate)"
    # VACOLS::Case.connection.execute(sql)


    joined = VACOLS::Case.joins(LEGACY_DOCKETED)
    vacols_appeals = joined.where(locdout_date: Time.zone.today)
  end

  # docketed_count from (
  # select locdout_date from (
  # select locstto, locdout::date as locdout_date from vacols.priorloc
  # inner join vacols.brieff on brieff.bfkey = priorloc.lockey
  # where bfac in ('1', '3', '7') and locstto = '01')
  # where locdout_date = current_date)

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

  # Purpose: To filter for legacy appeals that didnt already get an appeal docketed notification sent
  # Params: vacols_ids - An array of vacols ids for docketed legacy appeals
  # Return: an array of vacols ids
  def filter_duplicate_legacy_notifications(vacols_ids)
    duplicate_ids = Notification.where(appeals_id: vacols_ids).pluck(:appeals_id)
    vacols_ids.reject { |id| duplicate_ids.include?(id) }
  end

  # Purpose: To send the 'appeal docketed' notification for the legacy appeals
  # Params: vacols_ids - An array of filtered vacols ids for legacy appeals that didnt already have notifications sent
  # Return: The vacols ids that filtered out the duplicates
  def send_legacy_notifications(vacols_ids)
    vacols_ids.each do |vacols_id|
      AppellantNotification.notify_appellant(LegacyAppeal.find_by_vacols_id(vacols_id), "Appeal docketed")
    end
    vacols_ids
  end
end
