# frozen_string_literal: true

describe MultipleOpenRootChildTaskChecker do
  let!(:appeal1) { create(:appeal, :at_attorney_drafting) }
  let!(:appeal2) { create(:appeal, :with_schedule_hearing_tasks) }
  let!(:appeal3) { create(:appeal, :at_attorney_drafting) }

  context "there are no appeals with more than one open root-child task" do
    it "does not generate a report" do
      subject.call
      expect(subject.report?).to be_falsey
    end
  end

  context "there is at least one appeal with more than one open root-child task" do
    before do
      appeal1.tasks.find_by_type(:JudgeAssignTask).assigned!
      appeal1.reload

      appeal3.tasks.find_by_type(:DistributionTask).assigned!
      appeal3.reload
    end

    it "generates a report listing appeals" do
      subject.call
      expect(subject.report?).to be_truthy

      report_lines = subject.report.split("\n")
      expect(report_lines).to include "Found 2 appeals with multiple open root-children task types:"
      expect(report_lines).to include(/Appeal #{appeal1.id} => 2 tasks: .*JudgeAssignTask/)
      expect(report_lines).to include(/Appeal #{appeal3.id} => 2 tasks: .*DistributionTask/)
    end
  end
end
