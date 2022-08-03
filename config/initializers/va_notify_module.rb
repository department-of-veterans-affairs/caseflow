# frozen_string_literal: true

# Custom column types, particularly for VACOLS

class VaNotifyModule
  class << self
    def prepend_module
      model_list = [
        InitialTasksFactory, 
        PreDocketTask, 
        LegacyAppealDispatch,
        AmaAppealDispatch,
        ScheduleHearingTask,
        FoiaColocatedTask,
        AssignHearingDispositionTask,
        IhpTasksFactory,
        Task
      ]
      for model in model_list
          model_list[model].prepend(AppellantNotification)
      end
    end
  end
end
