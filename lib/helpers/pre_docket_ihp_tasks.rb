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
      if @appeal.appeal_state&.appeal_docketed
        puts("Appeal has been docketed. Aborting...")
        fail Interrupt
      end

      predocket_task.update!(parent_id: ihp_task.id)

      ihp_task.update!(parent_id: distribution_task.id)
      ihp_task.on_hold!
    rescue ActiveRecord::RecordNotFound => _error
      puts("Appeal was not found. Aborting...")
      raise Interrupt
    rescue StandardError => error
      puts("Something went wrong. Requires manual remediation. Error: #{error} Aborting...")
      raise Interrupt
    end

    private

    def root_task
      @root_task = @appeal.root_task
    end

    def distribution_task
      @distribution_task ||=
        if (distribution_tasks = @appeal.tasks.where(type: "DistributionTask").all).count > 1
          puts("Duplicate DistributionTask found. Remove the erroneous task and retry. Aborting...")
          fail Interrupt
        elsif distribution_tasks.count == 1
          distribution_tasks[0]
        elsif distribution_tasks.empty?
          dt = DistributionTask.create!(appeal: @appeal, parent: root_task)
          dt.on_hold!
          dt
        else
          puts("DistributionTask failed to inflate. Aborting...")
          fail Interrupt
        end
    end

    def predocket_task
      return @predocket_task unless @predocket_task.nil?

      if (predocket_tasks = @appeal.tasks.where(type: "PreDocketTask").all).count > 1
        puts("Duplicate PredocketTask found. Remove the erroneous task and retry. Aborting...")
        fail Interrupt
      end

      @predocket_task = predocket_tasks[0]
    end

    def ihp_task
      return @ihp_task unless @ihp_task.nil?

      ihp_tasks = @appeal.tasks.where(type: "InformalHearingPresentationTask").all
      if ihp_tasks.count > 1
        puts("Duplicate InformalHearingPresentationTask found. Remove the erroneous task and retry. Aborting...")
        fail Interrupt
      elsif ihp_tasks.count <= 0
        puts("No InformalHearingPresentationTask found. Aborting...")
        fail Interrupt
      end

      @ihp_task = ihp_tasks[0]
    end
  end
end
