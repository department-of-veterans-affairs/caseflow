# frozen_string_literal: true

class CorrespondencesAppealsTasks < Caseflow::Migration
  def up
    safety_assured do
      create_table :correspondences_appeals_tasks do |t|
        t.references :correspondence_appeal, foreign_key: true, index: false
        t.belongs_to :task, null: false, foreign_key: true

        t.timestamps
      end
    end
  end

  def down
    safety_assured do
      drop_table :correspondences_appeals_tasks
    end
  end
end
