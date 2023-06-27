# frozen_string_literal: true

class CancelTasksAndDescendants
  # @param task_relation [ActiveRecord::Relation] tasks to be cancelled
  # @return [NilClass]
  def self.call(task_relation = Task.none)
    new(task_relation).__send__(:call)
  end

  private

  def initialize(task_relation)
    @task_relation = task_relation
  end

  def call
    RequestStore[:current_user] = User.system_user

    @task_relation.find_each do |task|
      task.cancel_task_and_child_subtasks
    rescue StandardError => error
    end
  end
end
