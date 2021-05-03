# frozen_string_literal: true

describe JudgeAssignTaskCreator do
  let(:judge_user) { create(:user, :judge) }
  let(:judge_assign_task_creator) { JudgeAssignTaskCreator.new(appeal: appeal, judge: judge_user) }
  subject { judge_assign_task_creator.manage_judge_assign_tasks_for_appeal }

  describe "#manage_judge_assign_tasks_for_appeal" do
    # context "when an appeal does not have any judge assign tasks associated with it" do

    # end

    context "when an appeal has one judge assign task associated with it" do
      let(:appeal) { create(:appeal, :assigned_to_judge, associated_judge: judge_user) }
      it "creates a new judge assign task for the appeal" do
        subject
        # TODO: add expect statements
      end
    end
  end
end
