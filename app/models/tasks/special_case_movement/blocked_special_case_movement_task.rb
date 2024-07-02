# frozen_string_literal: true

##
# Task to record on the appeal that the special case movement manually assigned the case outside of automatic
#   case distribution and intentionally cancelled any tasks that were blocking distribution

class BlockedSpecialCaseMovementTask < SpecialCaseMovementTask
  private

  def distribute_to_judge
    Task.transaction do
      super
      cancel_tasks_blocking_distribution
    end
  end

  def cancel_tasks_blocking_distribution
    parent.cancel_descendants(instructions: instructions.first)
  end

  def verify_appeal_distributable
    if DistributionTask.open.where(appeal: appeal).empty?
      return true if appeal.appeal_split_process == true

      fail(Caseflow::Error::IneligibleForBlockedSpecialCaseMovement, appeal_id: appeal.id)
    end
  end
end
