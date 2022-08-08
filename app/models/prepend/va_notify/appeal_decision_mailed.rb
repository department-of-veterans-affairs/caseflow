 # frozen_string_literal: true
 
 #Module to notify appellant if an Appeal Decision is Mailed
  module AppealDecisionMailed
    @@template_name = self.name.split("::")[1]
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