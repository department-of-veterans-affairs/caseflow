# frozen_string_literal: true

# == Overview
#
# This module is used to intercept events triggered either on the Daily Docket or Case Details pages
#   that cause a hearing's state to shift (and by extension the appeal's state also). It is particularly
#   set up to look for instances where a hearing is being marked with a "Held" disposition.
module HearingHeld
  # Legacy Hearing Postponed from the Daily Docket
  # original method defined in app/models/legacy_hearing.rb
  def update_caseflow_and_vacols(hearing_hash)
    original_disposition = vacols_record.hearing_disp
    super_return_value = super
    new_disposition = vacols_record.hearing_disp
    if new_disposition == "H" && original_disposition != new_disposition
      appeal = LegacyAppeal.find(appeal_id)

      appeal&.appeal_state&.hearing_held_appeal_state_update_action!
    end
    super_return_value
  end

  # Legacy OR AMA Hearing Marked as "Held" from Queue
  # original method defined in app/models/tasks/assign_hearing_disposition_task.rb
  def update_hearing(hearing_hash)
    super_return_value = super

    if hearing_hash[:disposition] == Constants.HEARING_DISPOSITION_TYPES.held
      appeal.appeal_state.hearing_held_appeal_state_update_action!
    end

    super_return_value
  end

  # Purpose: Callback method when a hearing updates to also update appeal_states table
  #
  # Params: none
  #
  # Response: none
  def update_appeal_states_on_hearing_held
    appeal.appeal_state.hearing_held_appeal_state_update_action! if ama_hearing_held? || legacy_hearing_held?
  end

  private

  # Checks to see if the current object is an instance of a Hearing, and if its disposition has
  #  been set to "Held".
  #
  # @return [Boolean]
  #   True if self is an AMA hearing and its disposition is set to "Held". False otherwise.
  def ama_hearing_held?
    is_a?(Hearing) && disposition == Constants.HEARING_DISPOSITION_TYPES.held
  end

  # Checks to see if the current object is an instance of a LegacyHearing, and if its disposition has
  #  been set to "Held".
  #
  # @note The dispotion for a legacy hearing is located in the HEARSCHED table's hearing_disp column in
  #   in the VACOLS database.
  #
  # @return [Boolean]
  #   True if self is an AMA hearing and its disposition is set to "Held". False otherwise.
  def legacy_hearing_held?
    is_a?(LegacyHearing) && VACOLS::CaseHearing.find_by(hearing_pkseq: vacols_id)&.hearing_disp == "H"
  end
end
