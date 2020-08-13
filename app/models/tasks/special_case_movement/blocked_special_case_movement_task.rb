# frozen_string_literal: true

##
# Task to record on the appeal that the special case movement manually assigned the case outside of automatic
#   case distribution and cancelled any blocking tasks

class BlockedSpecialCaseMovementTask < SpecialCaseMovementTask

  private

  def distribute_to_judge
    Task.transaction do
      super
      # cancel any leftover open tasks on the distribution
      # parent.desecdents.open.cancel
      cancel_tasks_blocking_distribution
    end
  end

  # this just becomes cancel distribution subtree
  # (write some tests set to fail when we begin implementing
  # 14056Allow tasks to block dispatch)
  # careful not to close the root task accidentally
  def cancel_tasks_blocking_distribution
    parent.cancel_descendants
  end

  def verify_appeal_distributable
    # for us this means there is an open distribution task - right?
    if DistributionTask.open.where(appeal: appeal).empty?
      fail(Caseflow::Error::IneligibleForBlockedSpecialCaseMovement, appeal_id: appeal.id)
    end
  end
end
