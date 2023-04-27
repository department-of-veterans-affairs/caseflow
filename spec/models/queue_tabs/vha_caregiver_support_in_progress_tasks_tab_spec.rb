# frozen_string_literal: true

describe VhaCaregiverSupportInProgressTasksTab, :postgres do
  let(:tab) { VhaCaregiverSupportInProgressTasksTab.new(params) }
  let(:params) do
    {
      assignee: assignee
    }
  end
  let(:assignee) { VhaCaregiverSupport.singleton }

  describe ".column_names" do
    subject { tab.column_names }

    context "when only the assignee argument is passed when instantiating a VhaCaregiverSupportInProgressTasksTab" do
      it "returns the correct number of columns" do
        expect(subject.length).to eq(9)
      end
    end
  end

  describe "label, description, and tabname" do
    context "when instantiating a VhaCaregiverSupportInProgressTasksTab it should have labeling information" do
      let!(:vha_caregiver_support_in_progress_label) { tab.label }
      let!(:vha_caregiver_support_in_progress_description) { tab.description }
      let!(:vha_caregiver_support_in_progress_tab_name) { VhaCaregiverSupportInProgressTasksTab.tab_name }

      it "should have a label, description, and tab name" do
        expect(:vha_caregiver_support_in_progress_label).not_to be_nil
        expect(:vha_caregiver_support_in_progress_description).not_to be_nil
        expect(:vha_caregiver_support_in_progress_tab_name).not_to be_nil
      end
    end
  end

  describe ".tasks" do
    subject { tab.tasks }
    context "when there are tasks in progress with the assignee and others" do
      let!(:assignee_in_progress_tasks) do
        create_list(:vha_document_search_task, 5, :in_progress, assigned_to: assignee)
      end
      let!(:vha_camo_in_progress_tasks) { create_list(:vha_document_search_task, 9, :in_progress) }
      let!(:assignee_assigned_tasks) do
        create_list(:vha_document_search_task, 5, :assigned, assigned_to: assignee)
      end
      let!(:assignee_completed_tasks) do
        create_list(:vha_document_search_task, 4, :completed, assigned_to: assignee)
      end

      it "returns in progress tasks of the assignee and not other tasks or tasks from other organizations" do
        expect(subject).to match_array(
          [assignee_in_progress_tasks].flatten
        )

        expect(subject).not_to include(
          [vha_camo_in_progress_tasks].flatten
        )

        expect(subject).not_to include(
          [assignee_assigned_tasks].flatten
        )

        expect(subject).not_to include(
          [assignee_completed_tasks].flatten
        )
      end
    end

    context "when the assignee is not a Cargiver user" do
      let(:assignee) { create(:user) }

      it "raises an error" do
        expect { subject }.to raise_error(Caseflow::Error::MissingRequiredProperty)
      end
    end
  end
end
