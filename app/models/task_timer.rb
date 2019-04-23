# frozen_string_literal: true

class TaskTimer < ApplicationRecord
  belongs_to :task
  include Asyncable

  def veteran
    task.appeal.veteran
  end

  def self.requires_processing
    # Only process timers for tasks that are active.
    # Inline original definition of the requires_processing function due to limitations of mixins.
    with_active_tasks.processable.attemptable.unexpired.order_by_oldest_submitted
  end

  def self.with_active_tasks
    joins(:task).where("tasks.status not in (?)", Task.inactive_statuses).includes(:task)
  end
end
