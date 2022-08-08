# frozen_string_literal: true

# Prepending Appellant Notification modules to relevant classes
class VaNotifyModule
  if FeatureToggle.enabled?(:va_notify_prepend, user: RequestStore.store[:current_user])
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
