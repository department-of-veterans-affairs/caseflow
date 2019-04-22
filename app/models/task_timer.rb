# frozen_string_literal: true

class TaskTimer < ApplicationRecord
  belongs_to :task
  include Asyncable

  def veteran
    task.appeal.veteran
  end

  def requires_processing
    # Only process timers for tasks that are active
    task.active? ? super : false
  end
end
