# frozen_string_literal: true

##
# See https://github.com/department-of-veterans-affairs/caseflow/wiki/Timed-Tasks#tasktimer

class TaskTimer < CaseflowRecord
  belongs_to :task
  include Asyncable

  class << self
    def requires_processing
      # Only process timers for tasks that are active.
      # Inline original definition of the requires_processing function due to limitations of mixins.
      with_active_tasks.processable.attemptable.unexpired.order_by_oldest_submitted
    end

    def requires_cancelling
      with_closed_tasks.processable.order_by_oldest_submitted
    end

    def with_active_tasks
      includes(:task).where.not(tasks: { status: Task.closed_statuses })
    end

    def with_closed_tasks
      includes(:task).where(tasks: { status: Task.closed_statuses })
    end
  end

  def veteran
    task.appeal.veteran
  end
end

# (This section is updated by the annotate gem)
# == Schema Information
#
# Table name: task_timers
#
#  id                :bigint           not null, primary key
#  attempted_at      :datetime
#  canceled_at       :datetime
#  error             :string
#  last_submitted_at :datetime
#  processed_at      :datetime
#  submitted_at      :datetime
#  created_at        :datetime         not null
#  updated_at        :datetime         not null, indexed
#  task_id           :bigint           not null, indexed
#
# Foreign Keys
#
#  fk_rails_932e4eea15  (task_id => tasks.id)
#
