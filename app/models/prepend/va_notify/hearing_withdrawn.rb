# frozen_string_literal: true

# Module to notify appellant if Hearing is Withdrawn
module HearingWithdrawn
  extend AppellantNotification
  @@template_name = name.split("::")[1]
  def cancel!
    super
    AppellantNotification.notify_appellant(appeal, @@template_name)
  end
end
