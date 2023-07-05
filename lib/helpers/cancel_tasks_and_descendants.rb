# frozen_string_literal: true

require "securerandom"

class CancelTasksAndDescendants
  # @param task_relation [ActiveRecord::Relation] tasks to be cancelled
  # @return [true]
  def self.call(task_relation = Task.none)
    new(task_relation).__send__(:call)
  end

  private

  def initialize(task_relation)
    @task_relation = task_relation
    @request_id = SecureRandom.uuid
  end

  def call
    RequestStore[:current_user] = User.system_user

    log_time_elapsed { cancel_tasks }
  end

  def cancel_tasks
    @task_relation.find_each do |task|
      task.cancel_task_and_child_subtasks
    rescue StandardError => error
    end
  end

  def log_time_elapsed(&block)
    time_elapsed_in_seconds = Benchmark.realtime(&block)
    log("Elapsed time (sec): #{time_elapsed_in_seconds}")
  end

  def log(message, level: :info)
    Rails.logger.tagged("CancelTasksAndDescendants", @request_id) do
      Rails.logger.public_send(level, message)
    end
  end
end
