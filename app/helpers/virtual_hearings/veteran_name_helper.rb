# frozen_string_literal: true

##
# Helpers for use inside a template for virtual hearings
# emails and calendar invites.

module VirtualHearings::VeteranNameHelper
  def formatted_veteran_name(veteran)
    veteran.name.formatted(:readable_fi_last_formatted)
  end
end
