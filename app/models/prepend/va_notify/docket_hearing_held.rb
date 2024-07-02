# frozen_string_literal: true

# == Overview
#
# This module is used to intercept events triggered via the Daily Docket page to place a 'Held'
#  disposition onto a hearing.
module DocketHearingHeld
  # If a hearing is being assigned a disposition of 'Held' then this method will ensure that the
  #  hearing's appeal's appeal_states record has its hearing_scheduled attribute set back to false,
  #  as the appeal's latest milestone is no longer that its hearing has been scheduled, but rather that it's
  #  awaiting a decision.
  #
  # @return [AdvanceOnDocketMotion]
  #   If advance_on_docket_motion_attributes is non-nil.
  #   @see HearingsController#advance_on_docket_motion_params for information on what these params/attributes are.
  # @return [nil]
  #   If advance_on_docket_motion_attributes is nil/blank.
  def update_hearing
    super_return_value = super

    if hearing_updates[:disposition] == Constants.HEARING_DISPOSITION_TYPES.held
      hearing.appeal.appeal_state.hearing_held_appeal_state_update_action!
    end

    super_return_value
  end
end
