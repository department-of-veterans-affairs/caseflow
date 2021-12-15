# frozen_string_literal: true

describe BvaIntakeReadyForReviewTab, :postgres do
  let(:tab) { BvaIntakeReadyForReviewTab.new(params) }
  let(:params) do
    {
      assignee: assignee
    }
  end
  let(:assignee) { create(:bva) }

  describe ".column_names" do
    subject { tab.column_names }

    context "when only the assignee argument is passed when instantiating a BvaIntakeReadyForReviewTab" do
      let(:params) { { assignee: create(:bva) } }

      it "returns the correct number of columns" do
        expect(subject.length).to eq(6)
      end
    end
  end

  describe ".tasks" do
    subject { tab.tasks }

    context "when there are tasks assigned to the assignee" do
      let!(:assignee_ready_to_review) { create_list(:pre_docket_task, 4, :assigned, assigned_to: assignee) }
      let!(:assignee_completed_tasks) { create_list(:pre_docket_task, 3, :completed, assigned_to: assignee) }

      it "returns assignee's ready to review tasks" do
        expect(subject).to match_array(assignee_ready_to_review)
      end

      it "does not return assignee's completed tasks" do
        expect(subject).to_not match_array(assignee_completed_tasks)
      end

      context "when the assignee is a user" do
        let(:assignee) { create(:user) }

        it "raises an error" do
          expect { subject }.to raise_error(Caseflow::Error::MissingRequiredProperty)
        end
      end
    end
  end
end
