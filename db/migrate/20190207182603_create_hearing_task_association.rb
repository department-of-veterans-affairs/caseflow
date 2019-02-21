class CreateHearingTaskAssociation < ActiveRecord::Migration[5.1]
  def change
    create_table :hearing_task_associations do |t|
      t.belongs_to :hearing, polymorphic: true, null: false
      t.belongs_to :hearing_task, null: false
    end
  end
end
