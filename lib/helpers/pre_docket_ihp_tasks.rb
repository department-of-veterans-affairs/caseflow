# frozen_string_literal: true

# ************************
# Remediates IHP tasks that are generated prior to completion of Pre-Docket task
# If an InformalHearingPresentationTask is present prior to PreDocketTask being completed
# we create a new DistributionTask and set the InformalHearingPresentationTask as a child
# This will become a blocking task and allow the PreDocketTask to be completed prior to
# the InformalHearingPresentationTask being completed
# ************************
module WarRoom
  class PreDocketIhpTasks
    def run(appeal_uuid)
      @appeal = Appeal.find_appeal_by_uuid_or_find_or_create_legacy_appeal_by_vacols_id(appeal_uuid)
      if appeal.appeal_state.appeal_docketed
        puts("Appeal has been docketed. Aborting...")
        fail Interrupt
      end

      predocket_task.update!(parent_id: ihp_task.id)

      ihp_task.update!(parent_id: distribution_task.id)
      ihp_task.on_hold!
    end

    private

    def root_task
      @root_task = appeal.root_task
    end

    def distribution_task
      @distribution_task ||=
        if (dt = @appeal.tasks.where(type: "DistributionTask").first).blank?
          distribution_task = DistributionTask.create!(appeal: @appeal, parent: root_task)
          distribution_task.on_hold!
          distribution_task
        else
          dt.on_hold!
          dt
        end
    end

    def predocket_task
      @predocket_task ||=
        if (predocket_tasks = appeal.tasks.where(type: "PreDocketTask").all).count > 1
          puts("Duplicate PredocketTask found. Aborting...")
          fail Interrupt
        end

      predocket_tasks[0]
    end

    def ihp_task
      @ihp_task ||=
        if (ihp_tasks = appeal.tasks.where(type: "InformalHearingPresentationTask").all).count > 1
          puts("Duplicate InformalHearingPresentationTask found. Aborting...")
          fail Interrupt
        end

      ihp_tasks[0]
    end
  end
end
