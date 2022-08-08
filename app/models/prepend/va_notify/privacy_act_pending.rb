# frozen_string_literal: true

  #Module to notify appellant if Privacy Act Request is Pending
  module PrivacyActPending
    @@template_name = self.name.split("::")[1]

    def create_privacy_act_task
      super
      AppellantNotification.notify_appellant(self.appeal, @@template_name)
    end
  end