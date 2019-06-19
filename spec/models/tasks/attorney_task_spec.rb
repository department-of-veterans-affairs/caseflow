# frozen_string_literal: true

describe AttorneyTask do
  let!(:attorney) { create(:user) }
  let!(:judge) { create(:user) }
  let!(:attorney_staff) { create(:staff, :attorney_role, sdomainid: attorney.css_id) }
  let!(:judge_staff) { create(:staff, :judge_role, sdomainid: judge.css_id) }
  let(:appeal) { FactoryBot.create(:appeal) }
  let!(:parent) { create(:ama_judge_decision_review_task, assigned_by: judge, appeal: appeal) }

  context ".create" do
    subject do
      AttorneyTask.create(
        assigned_to: attorney,
        assigned_by: judge,
        appeal: appeal,
        parent: parent,
        status: Constants.TASK_STATUSES.assigned
      )
    end

    it "returns the correct label" do
      expect(AttorneyTask.new.label).to eq(
        COPY::ATTORNEY_TASK_LABEL
      )
    end

    context "there are no sibling tasks" do
      it "is valid" do
        expect(subject.valid?).to eq true
      end
    end

    context "there is a completed sibling task" do
      before do
        AttorneyTask.create!(
          assigned_to: attorney,
          assigned_by: judge,
          appeal: appeal,
          parent: parent,
          status: Constants.TASK_STATUSES.completed
        )
      end

      it "is valid" do
        expect(subject.valid?).to eq true
      end
    end

    context "there is an uncompleted sibling task" do
      before do
        AttorneyTask.create!(
          assigned_to: attorney,
          assigned_by: judge,
          appeal: appeal,
          parent: parent,
          status: Constants.TASK_STATUSES.assigned
        )
      end

      it "is not valid" do
        expect(subject.valid?).to eq false
        expect(subject.errors.messages[:parent].first).to eq "has open child tasks"
      end
    end
  end
end
