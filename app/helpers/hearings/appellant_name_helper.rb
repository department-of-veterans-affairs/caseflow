# frozen_string_literal: true

##
# Helpers for use inside a template for virtual hearings
# emails and calendar invites.

module Hearings::AppellantNameHelper
  def formatted_appellant_name(appeal)
    return appeal.appellant_fullname_readable || "the appellant" if appeal.appellant_is_not_veteran

    appeal&.veteran_fi_last_formatted || "the veteran"
  end

  def formatted_full_appellant_name(appeal)
    return appeal.appellant_fullname_readable if appeal.appellant_is_not_veteran

    appeal&.veteran_full_name
  end
end
