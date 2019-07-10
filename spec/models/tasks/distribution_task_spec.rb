# frozen_string_literal: true

require "rails_helper"

describe DistributionTask do
  describe "ready_for_distribution" do
    before do
      Timecop.freeze(Time.zone.today)
    end

    after do
      Timecop.return
    end

    let(:distribution_task) do
      DistributionTask.create!(
        appeal: create(:appeal),
        assigned_to: Bva.singleton,
        status: "on_hold"
      )
    end

    it "is set to assigned and ready for distribution is tracked when all child tasks are completed" do
      expect(distribution_task.ready_for_distribution?).to eq(false)

      child_task = create(:informal_hearing_presentation_task, parent: distribution_task)
      expect(distribution_task.ready_for_distribution?).to eq(false)

      child_task.update!(status: "completed")
      expect(distribution_task.ready_for_distribution?).to eq(true)
      expect(distribution_task.ready_for_distribution_at).to eq(Time.zone.now)

      another_child_task = create(:informal_hearing_presentation_task, parent: distribution_task)
      expect(distribution_task.ready_for_distribution?).to eq(false)

      Timecop.freeze(Time.zone.now + 1.day)

      another_child_task.update!(status: "completed")
      expect(distribution_task.ready_for_distribution?).to eq(true)
      expect(distribution_task.ready_for_distribution_at).to eq(Time.zone.now)
    end
  end
end
