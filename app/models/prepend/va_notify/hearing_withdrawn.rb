# frozen_string_literal: true

# Module to notify appellant if Hearing is Withdrawn
module HearingWithdrawn
  extend AppellantNotification

  # Legacy OR AMA Hearing Withdrawn from Queue
  # original method defined in app/models/tasks/assign_hearing_disposition_task.rb
  def update_hearing(hearing_hash)
    super_return_value = super
    if hearing_hash[:disposition] == Constants.HEARING_DISPOSITION_TYPES.cancelled && appeal.class.to_s == "Appeal"
      AppellantNotification.notify_appellant(appeal, Constants.EVENT_TYPE_FILTERS.withdrawal_of_hearing)
    end
    super_return_value
  end

  # Legacy Hearing Withdrawn from the Daily Docket
  # original method defined in app/models/legacy_hearing.rb
  def update_caseflow_and_vacols(hearing_hash)
    original_disposition = vacols_record.hearing_disp
    super_return_value = super
    new_disposition = vacols_record.hearing_disp
    if cancelled? && original_disposition != new_disposition
      appeal = LegacyAppeal.find(appeal_id)
      AppellantNotification.notify_appellant(appeal, Constants.EVENT_TYPE_FILTERS.withdrawal_of_hearing)
    end
    super_return_value
  end

  # Purpose: Callback method when a hearing updates to also update appeal_states table
  #
  # Params: none
  #
  # Response: none
  def update_appeal_states_on_hearing_withdrawn
    if is_a?(LegacyHearing)
      if VACOLS::CaseHearing.find_by(hearing_pkseq: vacols_id)&.hearing_disp == "C"
        appeal.appeal_state.hearing_withdrawn_appeal_state_update_action!
      end
    elsif is_a?(Hearing)
      if disposition == Constants.HEARING_DISPOSITION_TYPES.cancelled
        appeal.appeal_state.hearing_withdrawn_appeal_state_update_action!
      end
    end
  end
end
