class QualityReviewTask < GenericTask
  def create_from_root_task(root_task)
    create!(assigned_to: QualityReview.singleton, parent_id: root_task.id, appeal: root_task.appeal)
  end

  def mark_as_complete!
    BvaDispatchTask.create_and_assign(root_task)
    super
  end
end
