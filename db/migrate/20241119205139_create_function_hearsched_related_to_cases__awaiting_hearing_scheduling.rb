class CreateFunctionHearschedRelatedToCasesAwaitingHearingScheduling < ActiveRecord::Migration[6.1]
  def change
    create_function :hearsched_related_to_cases__awaiting_hearing_scheduling
  end
end
