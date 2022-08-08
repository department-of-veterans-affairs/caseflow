# frozen_string_literal: true
  
  #Module to notify appellant if Hearing is Withdrawn
  module HearingWithdrawn
    @@template_name = self.name.split("::")[1]
    def cancel!
      super
      AppellantNotification.notify_appellant(appeal, @@template_name)
    end
  end