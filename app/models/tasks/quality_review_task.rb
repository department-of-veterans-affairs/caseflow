class QualityReviewTask < GenericTask
  def available_actions(user)
    return super if assigned_to != user

    [
      {
        label: COPY::ACTION_READY_FOR_DISPATCH,
        value: "modal/mark_task_complete"
      },
      {
        label: COPY::ACTION_RETURN_TO_JUDGE,
        value: "modal/return_to_judge",
        data: {
          judge: completing_judge
        }
      }
    ]
  end

  def self.create_from_root_task(root_task)
    create!(assigned_to: QualityReview.singleton, parent_id: root_task.id, appeal: root_task.appeal)
  end

  def mark_as_complete!
    BvaDispatchTask.create_and_assign(root_task)
    super
  end

  private

  def completing_judge
    root_task.children.find { |task| task.type == "JudgeTask" }.assigned_to
  end
end
