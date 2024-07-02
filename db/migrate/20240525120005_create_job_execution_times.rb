# frozen_string_literal: true

# Add table to track the Time a Job was Last Executed
class CreateJobExecutionTimes < Caseflow::Migration
  def change
    create_table :job_execution_times, id: :serial do |t|
      t.string "job_name", comment: "Name of the Job whose Last Execution Time is being tracked", index: {unique: true}
      t.datetime "last_executed_at", comment: "DateTime value when the Job was Last Executed"
    end
  end
end
