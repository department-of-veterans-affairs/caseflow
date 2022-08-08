# frozen_string_literal: true

# Custom column types, particularly for VACOLS

class VaNotifyModule
  class << self
    if FeatureToggle.enabled?(:va_notify_prepend, user: RequestStore.store[:current_user])
      prepend_module
    end

    def prepend_module
      InitialTasksFactory.prepend(AppellantNotification::AppealDocketed)
      PreDocketTask.prepend(AppellantNotification::AppealDocketed)
      LegacyAppealDispatch.prepend(AppellantNotification::AppealDecisionMailed)
      AmaAppealDispatch.prepend(AppellantNotification::AppealDecisionMailed)
      ScheduleHearingTask.prepend(AppellantNotification::HearingScheduled)
      FoiaColocatedTask.prepend(AppellantNotification::PrivacyActPending)
      FoiaColocatedTask.prepend(AppellantNotification::PrivacyActComplete)
      AssignHearingDispositionTask.prepend(AppellantNotification::HearingPostponed)
      AssignHearingDispositionTask.prepend(AppellantNotification::HearingWithdrawn)
      IhpTasksFactory.prepend(AppellantNotification::IHPTaskPending)
      Task.prepend(AppellantNotification::IHPTaskComplete)
    end
  end
end
