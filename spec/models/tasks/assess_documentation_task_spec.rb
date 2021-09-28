# frozen_string_literal: true

describe AssessDocumentationTask, :postgres do
  let(:program_office) { VhaProgramOffice.create!(name: "Program Office", url: "Program Office") }
  let(:task) { create(:assess_documentation_task, assigned_to: program_office) }
  let(:user) { create(:user) }

  before { program_office.add_user(user) }

  describe "#available_actions" do
    subject { task.available_actions(user) }

    available_actions = [
      Constants.TASK_ACTIONS.TOGGLE_TIMED_HOLD.to_h,
      Constants.TASK_ACTIONS.VHA_ASSIGN_TO_REGIONAL_OFFICE.to_h
    ]

    it { is_expected.to eq available_actions }
  end
end
