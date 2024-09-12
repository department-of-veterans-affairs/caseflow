class AddTaskIdToCorrespondenceIntake < ActiveRecord::Migration[6.0]
  def change
    add_reference :correspondence_intakes, :task, foreign_key: true, index: false
  end
end
