   # frozen_string_literal: true

  #Module to notify appellant if Hearing is Scheduled
  module HearingScheduled
    @@template_name = self.name.split("::")[1]
    def create_hearing(task_values)
      super
      AppellantNotification.notify_appellant(self.appeal, @@template_name)
    end
  end