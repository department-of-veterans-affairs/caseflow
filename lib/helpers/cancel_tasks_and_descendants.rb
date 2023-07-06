# frozen_string_literal: true

require "securerandom"

class CancelTasksAndDescendants
  LOG_TAG = "CancelTasksAndDescendants"

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

    log_total_tasks_for_cancellation
    log_time_elapsed { cancel_tasks }
  end

  def cancel_tasks
    @task_relation.find_each do |task|
      log_cancelled(task) { task.cancel_task_and_child_subtasks }
    rescue StandardError => error
      log_errored(task, error)
    end
  end

  def log_total_tasks_for_cancellation
    log("Total tasks for cancellation: #{total_tasks_for_cancellation}")
  end

  def total_tasks_for_cancellation
    @total_tasks_for_cancellation ||= begin
      sum = 0
      @task_relation.find_each do |task|
        sum += cancellable_descendants_for(task).count
      end
      sum
    end
  end

  def log_cancelled(task, &block)
    task_ids = cancellable_descendants_for(task).pluck(:id)
    yield(block)
    log("Task ids #{task_ids} cancelled successfully")
  end

  def log_errored(task, error)
    task_ids = cancellable_descendants_for(task).pluck(:id)
    log("Task ids #{task_ids} not cancelled due to error - #{error}",
        level: :error)
  end

  def cancellable_descendants_for(task)
     Task.open.where(id: task.descendants)
  end

  def log_time_elapsed(&block)
    time_elapsed_in_seconds = Benchmark.realtime(&block)
    log("Elapsed time (sec): #{time_elapsed_in_seconds}")
  end

  def log(message, level: :info)
    Rails.logger.tagged(LOG_TAG, @request_id) do
      Rails.logger.public_send(level, message)
    end
  end
end
