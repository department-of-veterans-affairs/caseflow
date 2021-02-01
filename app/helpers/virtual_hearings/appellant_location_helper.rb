# frozen_string_literal: true

##
# Helpers for use inside a template for virtual hearings
# emails and calendar invites.

module VirtualHearings::AppellantLocationHelper
  def appellant_state(appeal)
    state_code = appeal.appellant_is_not_veteran ? appeal.appellant_state : appeal.veteran_state
    state_code || "??" # ?? Fallback if for some reason there isn't any state
  end
end
