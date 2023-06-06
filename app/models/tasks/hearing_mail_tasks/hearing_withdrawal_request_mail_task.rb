# frozen_string_literal: true

class HearingWithdrawalRequestMailTask < HearingRequestMailTask
  class << self
    def label
      "Hearing withdrawal request"
    end

    # Only users who are members of orgs where
    #
    #   def users_can_create_mail_task?
    #     true
    #   end
    #
    # can create mail tasks. Those orgs are the same 4 listed in the AC.
    #
    # This method is only being overridden so that HearingRequestMailTask
    # doesn't pop up in the dropdown.
    def allow_creation?(*)
      true
    end
  end
end
