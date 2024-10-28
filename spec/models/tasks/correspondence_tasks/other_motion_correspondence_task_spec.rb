# frozen_string_literal: true

RSpec.describe OtherMotionCorrespondenceTask, :postgres, type: :model do
  let(:lit_support_team) { LitigationSupport.singleton }

  describe ".available_actions" do
    subject { task.available_actions(user) }

    let(:user) { create(:user) }
    let(:task) { create(:other_motion_correspondence_task) }

    it "should include change task type action in available actions" do
      task.assigned_to = user
      expect(subject).to include(Constants.TASK_ACTIONS.CHANGE_TASK_TYPE.to_h)
    end
  end
end
