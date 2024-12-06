class CreateFunctionAssignAwaitingHearingScheduling < ActiveRecord::Migration[6.1]
  def change
    create_function :assign_awaiting_hearing_scheduling
  end
end
