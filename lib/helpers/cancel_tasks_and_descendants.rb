# frozen_string_literal: true

require "securerandom"

class CancelTasksAndDescendants
  LOG_TAG = "CancelTasksAndDescendants"

  # Cancels all tasks and descendant tasks for given Task relation
  #
  # @param task_relation [ActiveRecord::Relation] tasks to be cancelled
  # @return [NilClass]
  def self.call(task_relation = Task.none)
    new(task_relation).__send__(:call)
  end

  private

  def initialize(task_relation)
    @task_relation = task_relation
    @request_id = SecureRandom.uuid
    @logs = []
  end

  def call
    RequestStore[:current_user] = User.system_user

    with_paper_trail_options do
      log_time_elapsed { log_task_count_before_and_after { cancel_tasks } }
      print_logs_to_stdout
    end
  end

  # @note Temporarily sets the PaperTrail request options and executes the given
  #   block. The request options are only in effect on the current thread for
  #   the duration of the block.
  #   This is needed so that the PaperTrail `versions` records for cancelled
  #   tasks reflect the appropriate `whodunnit` and `request_id`.
  def with_paper_trail_options(&block)
    options = { whodunnit: User.system_user.id,
                controller_info: { request_id: @request_id } }

    PaperTrail.request(options, &block)
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
    append_to_application_logs(level, message)
    append_to_logs_for_stdout(message)
  end

  def append_to_application_logs(level, message)
    Rails.logger.tagged(LOG_TAG, @request_id) do
      Rails.logger.public_send(level, message)
    end
  end

  def append_to_logs_for_stdout(message)
    @logs << "[#{LOG_TAG}] [#{@request_id}] #{message}"
  end

  def print_logs_to_stdout
    puts @logs
  end
end
