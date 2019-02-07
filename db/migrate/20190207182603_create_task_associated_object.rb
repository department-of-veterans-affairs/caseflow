class CreateTaskAssociatedObject < ActiveRecord::Migration[5.1]
  def change
    create_table :task_associated_objects do |t|
      t.belongs_to :hearing, polymorphic: true, null: false
      t.belongs_to :hold_hearing_task, null: false
    end
  end
end
