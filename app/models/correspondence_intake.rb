# frozen_string_literal: true

class CorrespondenceIntake < ApplicationRecord
  belongs_to :task

  validates :task_id, presence: true
  validate :task_type_is_correct, on: :create

  def task_type_is_correct
    errors.add(:task, "Must be CorrespondenceIntakeTask") unless task&.type == CorrespondenceIntakeTask.name
  end
end
