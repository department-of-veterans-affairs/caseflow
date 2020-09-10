# frozen_string_literal: true

class HearingTaskTreeInitializer
  class << self
    # Initializes a task tree for an appeal with a pending travel board hearing.
    #
    # @note The tree is expected to look like:
    #                                        ┌────────────────────┐
    #   LegacyAppeal (legacy) ────────────── │ STATUS   │ ASGN_TO │
    #   └─RootTask                           │ on_hold  │ Bva     │
    #     └─HearingTask                      │ on_hold  │ Bva     │
    #       └─ScheduleHearingTask            │ on_hold  │ Bva     │
    #         └─ChangeHearingRequestTypeTask │ assigned │ Bva     │
    #                                        └────────────────────┘
    # @note This is in response to an initiative to reschedule travel board hearings due to
    #   COVID-19.
    # @note Travel board hearings are only available for legacy appeals.
    #
    # @param appeal [LegacyAppeal] the appeal to modify the task tree of
    #
    # @return       [LegacyAppeal]
    #   The legacy appeal with the new task tree
    def for_appeal_with_pending_travel_board_hearing(appeal)
      fail TypeError, "expected a legacy appeal" unless appeal.is_a?(LegacyAppeal)

      ActiveRecord::Base.multi_transaction do
        create_args = { appeal: appeal, assigned_to: Bva.singleton }

        root_task = RootTask.find_or_create_by!(**create_args)
        hearing_task = HearingTask.find_or_create_by!(**create_args, parent: root_task)
        schedule_hearing_task = ScheduleHearingTask.find_or_create_by!(**create_args, parent: hearing_task)
        ChangeHearingRequestTypeTask.find_or_create_by!(**create_args, parent: schedule_hearing_task)
      end

      appeal.reload
    end
  end
end
