# frozen_string_literal: true

# Module to notify appellant if an Appeal Decision is Mailed
module AppealDecisionMailed
  extend AppellantNotification
  # rubocop:disable all
  @@template_name = self.to_s
  # rubocop:enable all

  # def update_with_instructions(params)
  #   # original method defined in app/models/task.rb
  #   super
  #   if name == "BvaDispatchTask" && contested_claim?
  #     AppellantNotification.notify_appellant(@appeal, "#{@@template_name}Contested")
  #   elsif name == "BvaDispatchTask"
  #     AppellantNotification.notify_appellant(@appeal, "#{@@template_name}NonContested")
  #   end
  # end

  # Legacy
  # was previously working
  def complete_root_task!
    # original method defined in app/workflows/legacy_appeal_dispatch.rb
    super
    if appeal.contested_claim
      AppellantNotification.notify_appellant(@appeal, "#{@@template_name}Contested")
    else
      AppellantNotification.notify_appellant(@appeal, "#{@@template_name}NonContested")
    end
  end

  # AMA
  def complete_dispatch_root_task!
    # original method defined in app/workflows/ama_appeal_dispatch.rb
    super
    if appeal.contested_claim?
      AppellantNotification.notify_appellant(@appeal, "#{@@template_name}Contested")
    else
      AppellantNotification.notify_appellant(@appeal, "#{@@template_name}NonContested")
    end
  end
end
