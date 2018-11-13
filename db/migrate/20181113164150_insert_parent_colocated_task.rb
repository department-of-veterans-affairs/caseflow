class InsertParentColocatedTask < ActiveRecord::Migration[5.1]
  safety_assured

  def up
    ColocatedTask.all.find_each do |t|
      next if (t.parent && t.parent.assigned_to.is_a?(Colocated)) || t.assigned_to.is_a?(Colocated)

      org_task = ColocatedTask.create!(
        appeal: t.appeal,
        action: t.action,
        assigned_by: t.assigned_by,
        parent_id: t.parent_id,
        status: t.completed? ? Constants.TASK_STATUSES.completed : Constants.TASK_STATUSES.on_hold,
        assigned_to: Colocated.singleton
      )
      t.update!(parent_id: org_task.id)
    end
  end

  def down
    ColocatedTask.where(assigned_to: Colocated.singleton).find_each do |org_task|
      org_task.children.first.update!(parent_id: org_task.parent_id)
      org_task.destroy
    end
  end
end
