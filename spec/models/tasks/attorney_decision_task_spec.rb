# frozen_string_literal: true

describe AttorneyDecisionTask, focus: true do
  context ".create" do
    it "returns the correct label" do
      expect(AttorneyDecisionTask.new.label).to eq(
        COPY::ATTORNEY_TASK_LABEL
      )
    end

    it "returns the correct timeline title" do
      expect(AttorneyDecisionTask.new.timeline_title).to eq(
        COPY::CASE_TIMELINE_ATTORNEY_TASK
      )
    end
  end

  context ".create_many_from_params" do
    let!(:attorney) { create(:user) }
    let!(:judge) { create(:user) }
    let!(:attorney_staff) { create(:staff, :attorney_role, sdomainid: attorney.css_id) }
    let!(:judge_staff) { create(:staff, :judge_role, sdomainid: judge.css_id) }

    let!(:assign_tasks) { create_list(:ama_judge_task, 3, assigned_to: judge, parent: create(:root_task)) }
    let!(:params) do
      assign_tasks.map do |assign_task|
        {
          type: AttorneyDecisionTask.name,
          appeal: assign_task.appeal,
          parent_id: assign_task.id,
          assigned_by_id: judge.id,
          assigned_to_id: attorney.id,
          assigned_to_type: User.name
        }
      end
    end
    subject { AttorneyDecisionTask.create_many_from_params(params, judge) }

    it "returns the newly created tasks along with their new parents and old parents" do
      subject

      expect(subject.count).to eq 9

      attorney_tasks = subject.select { |task| task.type.eql? AttorneyDecisionTask.name }
      expect(attorney_tasks.count).to eq 3
      attorney_tasks.each do |attorney_task|
        expect(attorney_task.assigned_to).to eq attorney
        expect(attorney_task.assigned_by).to eq judge
        expect(attorney_task.parent.type).to eq JudgeDecisionReviewTask.name
        expect(attorney_task.status).to eq Constants.TASK_STATUSES.assigned
      end

      review_tasks = subject.select { |task| task.type.eql? JudgeDecisionReviewTask.name }
      expect(review_tasks.count).to eq 3
      review_tasks.each do |review_task|
        review_task.reload
        expect(review_task.assigned_to).to eq judge
        expect(review_task.children.first.type).to eq AttorneyDecisionTask.name
        expect(review_task.status).to eq Constants.TASK_STATUSES.on_hold
      end

      assign_tasks = subject.select { |task| task.type.eql? JudgeAssignTask.name }
      expect(assign_tasks.count).to eq 3
      expect(assign_tasks.all? { |assign_task| assign_task.status.eql? Constants.TASK_STATUSES.completed }).to eq true
    end
  end
end
