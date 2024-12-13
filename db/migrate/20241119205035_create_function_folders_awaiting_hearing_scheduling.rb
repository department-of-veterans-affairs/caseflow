class CreateFunctionFoldersAwaitingHearingScheduling < ActiveRecord::Migration[6.1]
  def change
    create_function :folders_awaiting_hearing_scheduling
  end
end
