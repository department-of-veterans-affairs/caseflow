# frozen_string_literal: true

describe SpecialtyCaseTeamAssignTask do
  let(:user) { create(:user) }
  let(:org) { SpecialtyCaseTeam.singleton }
  let(:sct_task) { create(:specialty_case_team_assign_task) }
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

  describe ".available_actions" do
    it "returns available actions" do
      expect(sct_task.available_actions(user)).to eq(expected_actions)
    end
  end
end
