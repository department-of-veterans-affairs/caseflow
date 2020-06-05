# frozen_string_literal: true

describe AppealsWithCancelledRootTaskCompletedDispatchQuery, :postgres do
  let!(:dispatched_appeal_with_cancelled_root_task) do
    appeal = create(:appeal, :with_post_intake_tasks)
    create(:bva_dispatch_task, :completed, appeal: appeal, parent: appeal.root_task)
    appeal.root_task.cancelled!
    appeal
  end

  describe "#call" do
    subject { described_class.new.call }

    it "returns array of matching appeals" do
      expect(subject).to match_array([dispatched_appeal_with_cancelled_root_task])
    end
  end
end
