# frozen_string_literal: true

describe BvaIntakeCompletedTab, :postgres do
  let(:tab) { BvaIntakeCompletedTab.new(params) }
  let(:params) do
    {
      assignee: assignee
    }
  end
  let(:assignee) { create(:bva) }

  describe ".column_names" do
    subject { tab.column_names }

    context "when only the assignee argument is passed when instantiating a BvaIntakeCompletedTab" do
      let(:params) { { assignee: create(:bva) } }

      it "returns the correct number of columns" do
        expect(subject.length).to eq 8
      end
    end
  end

  describe ".label" do
    subject { tab.label }

    it do
      is_expected.to eq COPY::ORGANIZATIONAL_QUEUE_COMPLETED_TAB_TITLE
      is_expected.to eq "Completed"
    end
  end

  describe ".description" do
    subject { tab.description }

    it do
      is_expected.to eq COPY::QUEUE_PAGE_COMPLETE_TASKS_DESCRIPTION
      is_expected.to eq "Cases completed:"
    end
  end

  describe ".self.tab_name" do
    subject { described_class.tab_name }

    it "matches expected tab name" do
      is_expected.to eq(Constants.QUEUE_CONFIG.BVA_INTAKE_COMPLETED_TAB_NAME)
      is_expected.to eq("bvaIntakeCompletedTab")
    end
  end

  describe ".tasks" do
    subject { tab.tasks }

    context "when there are tasks assigned to the assignee" do
      let!(:assignee_ready_to_review) { create_list(:pre_docket_task, 4, :assigned, assigned_to: assignee) }
      let!(:assignee_completed_tasks) { create_list(:pre_docket_task, 3, :completed, assigned_to: assignee) }

      it "does not return assignee's ready to review tasks" do
        expect(subject).to_not match_array(assignee_ready_to_review)
      end

      it "returns assignee's completed tasks" do
        expect(subject).to match_array(assignee_completed_tasks)
      end

      it "returns assignee's completed tasks that are older than 7 days" do
        assignee_completed_tasks.first.created_at = Time.zone.now - 1.year
        assignee_completed_tasks.first.updated_at = Time.zone.now - 1.year
        assignee_completed_tasks.first.assigned_at = Time.zone.now - 1.year
        assignee_completed_tasks.first.closed_at = Time.zone.now - 1.year
        assignee_completed_tasks.first.save
        expect(subject).to match_array(assignee_completed_tasks)
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
