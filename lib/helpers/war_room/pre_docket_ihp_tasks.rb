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
      if @appeal.root_task
        @root_task = @appeal.root_task
      else
        puts("No RootTask found. Aborting...")
        fail Interrupt
      end
    end

    def distribution_task
      @distribution_task ||=
        if (distribution_tasks = @appeal.tasks.where(type: "DistributionTask").all).count > 1
          puts("Duplicate DistributionTask found. Remove the erroneous task and retry. Aborting...")
          fail Interrupt
        elsif distribution_tasks.count == 1
          distribution_tasks[0].on_hold!
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

    # we look for only 1 PredocketTask.
    #   * If multiples are found we bail.
    #   * If none are found we bail.
    def predocket_task
      return @predocket_task unless @predocket_task.nil?

      predocket_tasks = @appeal.tasks.where(type: "PreDocketTask").all
      if predocket_tasks.count > 1
        puts("Multiple PredocketTask found. Remove the erroneous task and retry. Aborting...")
        fail Interrupt
      elsif predocket_tasks.count < 1
        puts("No PredocketTask found. This may already be fixed. Aborting...")
        fail Interrupt
      else
        @predocket_task = predocket_tasks[0]
      end
    end

    # we look for only 1 InformalHearingPresentationTask.
    #   * If multiples are found we bail.
    #   * If none are found we bail.
    # The status of the InformalHearingPresentationTask must be
    #   * assigned
    #   * on_hold
    #   * cancelled
    # If the status is anything else we bail.
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

      possible_ihp_task = ihp_tasks[0]
      if [Constants.TASK_STATUSES.assigned, Constants.TASK_STATUSES.on_hold, Constants.TASK_STATUSES.cancelled]
          .include?(possible_ihp_task.status)
        @ihp_task = possible_ihp_task
      else
        puts("InformalHearingPresentationTask is not in the correct status for remediation. Aborting...")
        fail Interrupt
      end
    end
  end
end
