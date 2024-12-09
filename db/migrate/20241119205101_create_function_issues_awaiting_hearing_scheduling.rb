class CreateFunctionIssuesAwaitingHearingScheduling < ActiveRecord::Migration[6.1]
  def change
    create_function :issues_awaiting_hearing_scheduling
  end
end
