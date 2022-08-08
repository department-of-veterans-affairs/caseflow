# frozen_string_literal: true

# Module to notify appellant if an Appeal Decision is Mailed
module AppealDecisionMailed
  extend AppellantNotification
  @@template_name = name.split("::")[1]
  # Aspect for Legacy Appeals
  def complete_root_task!
    super
    AppellantNotification.notify_appellant(@appeal, @@template_name)
  end

  # Aspect for AMA Appeals
  def complete_dispatch_root_task!
    super
    AppellantNotification.notify_appellant(@appeal, @@template_name)
  end
end
