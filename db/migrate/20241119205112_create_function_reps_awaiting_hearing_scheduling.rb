class CreateFunctionRepsAwaitingHearingScheduling < ActiveRecord::Migration[6.1]
  def change
    create_function :reps_awaiting_hearing_scheduling
  end
end
