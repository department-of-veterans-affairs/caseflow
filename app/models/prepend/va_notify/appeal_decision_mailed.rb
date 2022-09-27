# frozen_string_literal: true

# Module to notify appellant if an Appeal Decision is Mailed
module AppealDecisionMailed
  extend AppellantNotification
  # rubocop:disable all
  @@template_name = "Appeal decision mailed"
  # rubocop:enable all

  # # Legacy
  # def complete_root_task!
  #   # original method defined in app/workflows/legacy_appeal_dispatch.rb
  #   super_return_value = super
  #   if appeal.contested_claim
  #     AppellantNotification.notify_appellant(@appeal, "#{@@template_name} (Contested claims)")
  #   else
  #     AppellantNotification.notify_appellant(@appeal, "#{@@template_name} (Non-contested claims)")
  #   end
  #   super_return_value
  # end

  # # AMA
  # def complete_dispatch_root_task!
  #   # original method defined in app/workflows/ama_appeal_dispatch.rb
  #   super_return_value = super
  #   if appeal.contested_claim?
  #     AppellantNotification.notify_appellant(@appeal, "#{@@template_name} (Contested claims)")
  #   else
  #     AppellantNotification.notify_appellant(@appeal, "#{@@template_name} (Non-contested claims)")
  #   end
  #   super_return_value
  # end

  def process!
    # original method defined in app/models/decision_document.rb
    super_return_value = super
    if appeal.contested_claim?
      AppellantNotification.notify_appellant(@appeal, "#{@@template_name} (Contested claims)")
    else
      AppellantNotification.notify_appellant(@appeal, "#{@@template_name} (Non-contested claims)")
    end
    super_return_value
  end

end
