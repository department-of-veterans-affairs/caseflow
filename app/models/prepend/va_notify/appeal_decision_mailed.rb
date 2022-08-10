# frozen_string_literal: true

# Module to notify appellant if an Appeal Decision is Mailed
module AppealDecisionMailed
  extend AppellantNotification
  # rubocop:disable all
  @@template_name = self.to_s
  # rubocop:enable all

  def update_with_instructions(params)
    super
    if name == "BvaDispatchTask" && contested_claim?
      AppellantNotification.notify_appellant(@appeal, "#{@@template_name}Contested")
    elsif name == "BvaDispatchTask"
      AppellantNotification.notify_appellant(@appeal, "#{@@template_name}NonContested")
    end
  end
end
