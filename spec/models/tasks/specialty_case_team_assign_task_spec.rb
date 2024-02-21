# frozen_string_literal: true

describe SpecialtyCaseTeamAssignTask do
  let(:sct_user) { create(:user) }
  let(:sct_org) { SpecialtyCaseTeam.singleton }
  let(:sct_assign_task) { create(:specialty_case_team_assign_task, :action_required) }
  let(:expected_actions) do
    [
      Constants.TASK_ACTIONS.ASSIGN_TO_ATTORNEY.to_h
    ]
  end

  before do
    sct_org.add_user(sct_user)
    User.authenticate!(user: sct_user)
  end

  describe ".label" do
    it "returns correct label" do
      expect(sct_assign_task.label).to eq(COPY::SPECIALTY_CASE_TEAM_ASSIGN_TASK_LABEL)
    end
  end

  describe ".available_actions" do
    it "returns available actions" do
      expect(sct_assign_task.available_actions(sct_user)).to eq(expected_actions)
    end
  end
end
