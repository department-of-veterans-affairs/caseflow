class TaskTimer < ApplicationRecord
  belongs_to :task
  include Asyncable

  def veteran
    task.appeal.veteran
  end
end
