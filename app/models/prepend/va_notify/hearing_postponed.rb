# frozen_string_literal: true

# Module to notify appellant if Hearing is Postponed
module HearingPostponed
  extend AppellantNotification
  @@template_name = name.split("::")[1]
  def postpone!
    super
    AppellantNotification.notify_appellant(appeal, @@template_name)
  end
end
