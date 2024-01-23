# frozen_string_literal: true

# Active Job that handles polling VACOLS for legacy appeals that have been recently docketed

class PollDocketedLegacyAppealsJob < CaseflowJob
  queue_as :low_priority
  application_attr :hearing_schedule

  before_perform do |job|
    JOB_ATTR = job
  end

  LEGACY_DOCKETED = "INNER JOIN priorloc ON brieff.bfkey = priorloc.lockey WHERE brieff.bfac IN ('1','3','7') AND locstto = '01' AND trunc(locdout) = trunc(sysdate)"

  def perform
    RequestStore.store[:current_user] = User.system_user
    vacols_ids = most_recent_docketed_appeals(LEGACY_DOCKETED)
    filtered_vacols_ids = filter_duplicate_legacy_notifications(vacols_ids)
    send_legacy_notifications(filtered_vacols_ids)
  end

  # Purpose: To get a list of all vacols ids for the most recent docketed appeals to be used for sending notifications
  # Return: An array of vacols ids
  def most_recent_docketed_appeals(query)
    vacols_appeals = VACOLS::Case.joins(query).pluck(:bfkey)
    Rails.logger.info("Querying for most recent docketed appeals, found #{vacols_appeals.count} ids")
    vacols_appeals
  end

  # Purpose: To filter for legacy appeals that didnt already get an appeal docketed notification sent
  # Params: vacols_ids - An array of vacols ids for docketed legacy appeals
  # Return: an array of vacols ids
  def filter_duplicate_legacy_notifications(vacols_ids)
    duplicate_ids = Notification.where(appeals_id: vacols_ids).pluck(:appeals_id)
    Rails.logger.info("Filtering for ids that already had appeal docketed notifications sent already, found #{duplicate_ids.count} duplicate ids")
    vacols_ids.reject { |id| duplicate_ids.include?(id) }
  end

  # rubocop:disable all
  # Purpose: To send the 'appeal docketed' notification for the legacy appeals
  # Params: vacols_ids - An array of filtered vacols ids for legacy appeals that didnt already have notifications sent
  # Return: The vacols ids that filtered out the duplicates
  def send_legacy_notifications(vacols_ids)
    Rails.logger.info("Found #{vacols_ids.count} legacy appeals that have been recently docketed and have not gotten docketed notifications")
    vacols_ids.each do |vacols_id|
      begin
        AppellantNotification.notify_appellant(LegacyAppeal.find_by_vacols_id(vacols_id), "Appeal docketed")
      rescue Exception => ex 
        Rails.logger.error("#{ex.class}: #{ex.message} for vacols id:#{vacols_id} on #{JOB_ATTR.class} of ID:#{JOB_ATTR.job_id}\n #{ex.backtrace.join("\n")}")
        next
      end
    end
    vacols_ids
  end
  # rubocop:enable all
end
