# frozen_string_literal: true

# Module to notify appellant if an Appeal Decision is Mailed
module AppealDecisionMailed
  extend AppellantNotification
  # rubocop:disable all
  @@template_name = self.to_s
  # rubocop:enable all

  # Aspect for Legacy Appeals
  def complete_root_task!
    # original method defined in app/workflows/legacy_appeal_dispatch.rb
    super
    AppellantNotification.notify_appellant(@appeal, @@template_name)
  end

  # Aspect for AMA Appeals
  def complete_dispatch_root_task!
    # original method defined in app/workflows/ama_appeal_dispatch.rb
    super
    AppellantNotification.notify_appellant(@appeal, @@template_name)
  end
end
