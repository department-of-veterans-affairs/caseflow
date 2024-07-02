# frozen_string_literal: true

# Active Job that handles polling VACOLS for legacy appeals that have been recently docketed

class PollDocketedLegacyAppealsJob < CaseflowJob
  queue_as :low_priority
  application_attr :hearing_schedule

  before_perform do |job|
    JOB_ATTR = job
  end

  LEGACY_DOCKETED = "INNER JOIN priorloc ON \
  brieff.bfkey = priorloc.lockey WHERE \
  brieff.bfac IN ('1','3','7') AND locstto = '01' AND trunc(locdout) = trunc(sysdate)"

  def perform
    RequestStore.store[:current_user] = User.system_user
    vacols_ids = most_recent_docketed_appeals(LEGACY_DOCKETED)
    filtered_vacols_ids = filter_duplicate_legacy_notifications(vacols_ids)
    create_corresponding_appeal_states(filtered_vacols_ids.uniq)
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
    Rails.logger.info("Filtering for ids that already had appeal docketed notifications sent already, found #{duplicate_ids.count} duplicate ids") # rubocop:disable  Layout/LineLength
    vacols_ids.reject { |id| duplicate_ids.include?(id) }
  end

  # Purpose: To create an AppealState record for the docketed legacy  appeals
  # Params: An array of vacols_ids for docketed legacy appeals
  # Return: None
  def create_corresponding_appeal_states(vacols_ids)
    vacols_ids.each do |vacols_id|
      appeal = LegacyAppeal.find_by_vacols_id(vacols_id)
      appeal_state = AppealState.find_by(appeal: appeal)
      if appeal_state
        appeal_state.appeal_docketed = true
        appeal_state.save!
      else
        AppealState.new(appeal: appeal,
                        created_by_id: User.system_user.id,
                        appeal_docketed: true)
          .save!
      end
    end
  end

  # rubocop:disable all
  # Purpose: To send the 'appeal docketed' notification for the legacy appeals
  # Params: vacols_ids - An array of filtered vacols ids for legacy appeals that didnt already have notifications sent
  # Return: The vacols ids that filtered out the duplicates
  def send_legacy_notifications(vacols_ids)
    Rails.logger.info("Found #{vacols_ids.count} legacy appeals that have been recently docketed and have not gotten docketed notifications")
    vacols_ids.each do |vacols_id|
      begin
        AppellantNotification.notify_appellant(
          LegacyAppeal.find_by_vacols_id(vacols_id),
          Constants.EVENT_TYPE_FILTERS.appeal_docketed
        )
      rescue Exception => ex
        Rails.logger.error("#{ex.class}: #{ex.message} for vacols id:#{vacols_id} on #{JOB_ATTR.class} of ID:#{JOB_ATTR.job_id}\n #{ex.backtrace.join("\n")}")
        next
      end
    end
    vacols_ids
  end
  # rubocop:enable all
end
