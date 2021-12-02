# frozen_string_literal: true

describe MultipleOpenRootChildTaskChecker do
  let!(:appeal1) { create(:appeal, :at_attorney_drafting) }
  let!(:appeal2) { create(:appeal, :with_schedule_hearing_tasks) }

  it "reports to correct slack channel" do
    subject.call
    expect(subject.slack_channel).to eq("#appeals-echo")
  end

  context "there are no appeals with more than one open hearing task" do
    it "does not generate a report" do
      subject.call
      expect(subject.report?).to be_falsey
    end
  end

  context "there is at least one appeal with more than one open hearing task" do
    let(:judge_assign_task) { appeal1.tasks.find_by_type(:JudgeAssignTask) }
    before do
      judge_assign_task.assigned!
      appeal1.reload
    end

    it "generates a report with the expected content" do
      subject.call

      expect(subject.report?).to be_truthy

      report_lines = subject.report.split("\n")
      expect(report_lines).to include "Found 1 appeal with multiple open root-children task types:"
      expect(report_lines).to include "Appeal #{appeal1.id} => 2 tasks"
    end
  end
end
