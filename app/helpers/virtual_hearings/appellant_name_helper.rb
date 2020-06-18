# frozen_string_literal: true

##
# Helpers for use inside a template for virtual hearings
# emails and calendar invites.

module VirtualHearings::AppellantNameHelper
  def formatted_appellant_name(appeal)
    return appeal.appellant_fullname_readable || "the appellant" if appeal.appellant_is_not_veteran

    appeal&.veteran&.name&.formatted(:readable_fi_last_formatted) || "the veteran"
  end

  def appellant_or_veteran(appeal)
    return "Appellant" if appeal.appellant_is_not_veteran

    "Veteran"
  end
end
