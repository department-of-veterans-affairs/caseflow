# frozen_string_literal: true

require "securerandom"

class CancelTasksAndDescendants
  LOG_TAG = "CancelTasksAndDescendants"

  # Cancels all tasks and descendant tasks for given Task relation
  #
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

    log_time_elapsed { log_task_count_before_and_after { cancel_tasks } }
  end

  def cancel_tasks
    @task_relation.find_each do |task|
      log_cancelled(task) { task.cancel_task_and_child_subtasks }
    rescue StandardError => error
      log_errored(task, error)
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
    # Note: The result of `Task #descendants` also includes the instance itself
    Task.open.where(id: task.descendants)
  end

  def log_task_count_before_and_after(&block)
    initial_count = count_of_cancellable_tasks
    log_total_tasks_for_cancellation(initial_count)
    yield(block)
    final_count = initial_count - count_of_cancellable_tasks
    log_cancelled_successfully(final_count)
  end

  def count_of_cancellable_tasks
    sum = 0
    @task_relation.find_each do |task|
      sum += cancellable_descendants_for(task).count
    end
    sum
  end

  def log_total_tasks_for_cancellation(count)
    log("Total tasks for cancellation: #{count}")
  end

  def log_cancelled_successfully(count)
    log("Tasks cancelled successfully: #{count}")
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
