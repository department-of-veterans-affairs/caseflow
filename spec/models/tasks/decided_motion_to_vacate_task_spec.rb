# frozen_string_literal: true

RSpec.describe DecidedMotionToVacateTask, :postgres, type: :model do
  let(:lit_support_team) { LitigationSupport.singleton }

  describe ".automatically_create_org_task" do
    subject { create(:denied_motion_to_vacate_task) }

    it "should automatically create org task" do
      subject
      org_task = DeniedMotionToVacateTask.find_by(assigned_to: lit_support_team)
      expect(org_task).to_not be nil
    end
  end

  describe ".available_actions" do
    subject { task.available_actions(attorney) }

    let(:attorney) { create(:user) }
    let(:task) { create(:denied_motion_to_vacate_task) }

    it "should include Pulac Cerullo action in available actions" do
      expect(subject).to include(Constants.TASK_ACTIONS.LIT_SUPPORT_PULAC_CERULLO.to_h)
    end
  end
end
