# frozen_string_literal: true

describe AppealsWithMoreThanOneOpenHearingTaskChecker do
  let(:appeal1) { create(:appeal, :with_schedule_hearing_tasks) }
  let(:appeal2) { create(:appeal, :with_schedule_hearing_tasks) }
  let(:legacy_appeal) { create(:legacy_appeal, :with_schedule_hearing_tasks) }

  it "reports to correct slack channel" do
    subject.call

    expect(subject.slack_channel).to eq("#appeals-tango")
  end

  context "there are no appeals with more than one open hearing task" do
    it "does not generate a report" do
      subject.call
      expect(subject.report?).to be_falsey
    end
  end

  context "there is at least one appeal with more than one open hearing task" do
    before do
      ScheduleHearingTask.create!(appeal: appeal2, parent: appeal2.root_task)
    end

    it "generates a report with the expected content" do
      subject.call

      expect(subject.report?).to be_truthy

      report_lines = subject.report.split("\n")
      expect(report_lines).to include "Found 1 appeal with more than one open hearing task: "
      expect(report_lines).to include "`Appeal.find(#{appeal2.id})` (2 open HearingTasks)"
    end

    context "there are two appeals with more than one open hearing task" do
      before do
        ScheduleHearingTask.create!(appeal: legacy_appeal, parent: legacy_appeal.root_task)
      end

      it "generates a report with the expected content" do
        subject.call

        expect(subject.report?).to be_truthy

        report_lines = subject.report.split("\n")
        expect(report_lines).to include "Found 2 appeals with more than one open hearing task: "
        expect(report_lines).to include "`Appeal.find(#{appeal2.id})` (2 open HearingTasks)"
        expect(report_lines).to include "`LegacyAppeal.find(#{legacy_appeal.id})` (2 open HearingTasks)"
      end
    end
  end
end
