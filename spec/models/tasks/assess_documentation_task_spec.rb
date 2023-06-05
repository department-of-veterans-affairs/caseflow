# frozen_string_literal: true

describe AssessDocumentationTask, :postgres do
  let(:user) { create(:user) }

  before do
    FeatureToggle.enable!(:visn_predocket_workflow)
  end

  after do
    FeatureToggle.disable!(:visn_predocket_workflow)
  end

  context "#available_actions" do
    describe "for program office user" do
      let(:program_office) { VhaProgramOffice.create!(name: "Program Office", url: "Program Office") }
      let(:program_office_task) { create(:assess_documentation_task, assigned_to: program_office) }

      before { program_office.add_user(user) }

      subject { program_office_task.available_actions(user) }

      available_actions = [
        Constants.TASK_ACTIONS.TOGGLE_TIMED_HOLD.to_h,
        Constants.TASK_ACTIONS.READY_FOR_REVIEW.to_h,
        Constants.TASK_ACTIONS.VHA_ASSIGN_TO_REGIONAL_OFFICE.to_h,
        Constants.TASK_ACTIONS.VHA_PROGRAM_OFFICE_RETURN_TO_CAMO.to_h,
        Constants.TASK_ACTIONS.VHA_MARK_TASK_IN_PROGRESS.to_h
      ]

      it { is_expected.to eq available_actions }
    end

    describe "for regional office user" do
      let(:regional_office) { VhaRegionalOffice.create!(name: "Regional Office", url: "Regional Office") }
      let(:regional_office_task) { create(:assess_documentation_task, assigned_to: regional_office) }

      before { regional_office.add_user(user) }

      subject { regional_office_task.available_actions(user) }

      available_actions = [
        Constants.TASK_ACTIONS.TOGGLE_TIMED_HOLD.to_h,
        Constants.TASK_ACTIONS.READY_FOR_REVIEW.to_h,
        Constants.TASK_ACTIONS.VHA_REGIONAL_OFFICE_RETURN_TO_PROGRAM_OFFICE.to_h,
        Constants.TASK_ACTIONS.VHA_MARK_TASK_IN_PROGRESS.to_h
      ]

      it { is_expected.to eq available_actions }
    end
  end
end
