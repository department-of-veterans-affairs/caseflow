# frozen_string_literal: true

# Module to notify appellant if IHP Task is pending
module IhpTaskPending
  extend AppellantNotification
  @@template_name = name.split("::")[1]
  def create_ihp_tasks!
    super
    AppellantNotification.notify_appellant(appeal, @@template_name)
  end
end
