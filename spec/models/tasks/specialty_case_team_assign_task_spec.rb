# frozen_string_literal: true

describe SpecialtyCaseTeamAssignTask do
  let(:user) { create(:user) }
  let(:org) { SpecialtyCaseTeam.singleton }
  let(:sct_task) { create(:sct_assign_task) }
  let(:expected_actions) do
    [
      Constants.TASK_ACTIONS.ASSIGN_TO_ATTORNEY.to_h
    ]
  end

  before do
    org.add_user(user)
  end

  describe ".label" do
    it "returns correct label" do
      expect(sct_task.label).to eq(COPY::SPECIALTY_CASE_TEAM_ASSIGN_TASK_LABEL)
    end
  end

  describe ".additional_available_actions" do
    it "returns additional available actions" do
      expect(sct_task.additional_available_actions(user)).to eq(expected_actions)
    end
  end
end
