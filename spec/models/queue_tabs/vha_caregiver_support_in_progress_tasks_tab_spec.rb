# frozen_string_literal: true

describe VhaCaregiverSupportInProgressTasksTab, :postgres do
  let(:tab) { VhaCaregiverSupportInProgressTasksTab.new(params) }
  let(:params) do
    { assignee: assignee }
  end
  let(:assignee) { VhaCaregiverSupport.singleton }
  # let(:vha_po_org) { VhaProgramOffice.create!(name: "Vha Program Office", url: "vha-po") }
  # let(:visn_org) { VhaRegionalOffice.create!(name: "Vha Regional Office", url: "vha-visn") }

  describe ".column_names" do
    subject { tab.column_names }

    context "when only the assignee argument is passed when instantiating a VhaCamoInProgressTasksTab" do
      # let(:params) { { assignee: VhaCaregiverSupport.singleton } }

      it "returns the correct number of columns" do
        expect(subject.length).to eq(7)
      end
    end
  end

  describe ".tasks" do
    subject { tab.tasks }
    # Copying this from education rpo but unknown if it is neccessary for the other objects to see the items
    context "when there are tasks in progress with the assignee and others" do
      let!(:assignee_in_progress_tasks) do
        create_list(:vha_caregiver_documentation_task, 5, :in_progress, assigned_to: assignee)
      end
      let!(:other_in_progress_tasks) { create_list(:vha_caregiver_documentation_task, 9) }

      it "returns in progress tasks of the assignee and not any other folks" do
        expect(subject).to match_array(
          [assignee_in_progress_tasks].flatten
        )

        expect(subject).not_to include(
          [other_in_progress_tasks].flatten
        )
      end
    end

    context "when there are tasks assigned to the assignee" do
      let!(:assignee_assigned_tasks) do
        create_list(:vha_caregiver_documentation_task, 5, :assigned, assigned_to: assignee)
      end

      it "does not return the assigned tasks" do
        expect(subject).not_to include(
          [assignee_assigned_tasks].flatten
        )
      end
    end

    context "when there are tasks completed by the assignee" do
      let!(:assignee_completed_tasks) do
        create_list(:vha_caregiver_documentation_task, 4, :completed, assigned_to: assignee)
      end

      it "does not return the completed tasks" do
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
