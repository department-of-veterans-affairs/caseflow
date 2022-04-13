# frozen_string_literal: true

describe EducationEmoAssignedTasksTab, :postgres do
  let(:tab) { EducationEmoAssignedTasksTab.new(params) }
  let(:params) do
    {
      assignee: assignee
    }
  end
  let(:assignee) { create(:education_emo) }

  describe ".column_names" do
    subject { tab.column_names }

    context "when only the assignee argument is passed when instantiating an EducationEmoAssignedTasksTab" do
      let(:params) { { assignee: create(:education_emo) } }

      it "returns the correct number of columns" do
        expect(subject.length).to eq(7)
      end
    end
  end

  describe ".tasks" do
    subject { tab.tasks }

    context "when the EMO sends appeal to BVA Intake for docketing" do
    end

    # This can occur if the appeal isn't actually education related
    context "when the EMO sends appeal back to BVA Intake because of an error" do
    end

    context "when the EMO sends the appeal to an RPO" do
    end

    context "when an RPO sends an appeal back to the EMO" do
    end

    context "when an RPO sends an appeal directly to BVA Intake" do
    end

    context "when BVA Intake dockets an appeal after having received it" do
    end
  end
end
