# frozen_string_literal: true

describe StuckVirtualHearingsChecker, :postgres do
  let(:hearing_day) { create(:hearing_day, scheduled_for: Time.zone.today + 2.weeks) }

  it "reports to correct slack channel" do
    subject.call

    expect(subject.slack_channel).to eq("#appeals-tango")
  end

  context "there are no stuck virtual hearings" do
    let!(:virtual_hearing) do
      create(
        :virtual_hearing, :initialized, :all_emails_sent,
        hearing: create(:hearing, regional_office: "RO13")
      )
    end

    it "does not generate a report" do
      subject.call
      expect(subject.report?).to be_falsey
    end
  end

  context "there is a stuck virtual hearing but it was updated less than 2 hours ago" do
    let!(:virtual_hearing_too_recent) do
      create(
        :virtual_hearing, :all_emails_sent,
        updated_at: Time.zone.now,
        hearing: create(:hearing, regional_office: "RO13")
      )
    end

    it "does not generate a report" do
      subject.call

      # does not report a virtual hearing that was updated less than 2 hours ago
      expect(subject.report?).to be_falsey
    end
  end

  context "there is a virtual hearing with pending conference" do
    let!(:virtual_hearing) do
      create(
        :virtual_hearing, :initialized, :all_emails_sent,
        updated_at: Time.zone.now - 3.hours,
        hearing: create(:hearing, regional_office: "RO13")
      )
    end
    let!(:virtual_hearing_pending) do
      create(
        :virtual_hearing, :all_emails_sent,
        updated_at: Time.zone.now - 3.hours,
        hearing: create(:hearing, regional_office: "RO13")
      )
    end

    context "reruns the job for each stuck virtual hearing" do
      it "does not generate a report" do
        subject.call
        expect(subject.report?).to be_falsey
      end
    end

    context "rerunning the job also results in stuck virtual hearing" do
      before { allow_any_instance_of(described_class).to receive(:rerun_jobs).and_return(nil) }

      it "builds a report containing only pending virtual hearing" do
        subject.call

        report_lines = subject.report.split("\n")
        expect(report_lines).to include("Found 1 stuck virtual hearing: ")
        pending_line = report_lines[1]
        expect(pending_line).to include "VirtualHearing.find(#{virtual_hearing_pending.id})"
        expect(pending_line).to include "last attempted: never"
        display_scheduled_for = virtual_hearing_pending.hearing.scheduled_for.strftime("%a %m/%d")
        expect(pending_line).to include "scheduled for: #{display_scheduled_for}"
        expect(pending_line).to include "updated by: #{virtual_hearing_pending.updated_by.css_id}"
        expect(pending_line).to include "UUID: #{virtual_hearing_pending.hearing.uuid}"
      end
    end
  end

  context "there is a virtual hearing where all emails haven't sent" do
    let!(:virtual_hearing) do
      create(
        :virtual_hearing, :initialized, :all_emails_sent,
        updated_at: Time.zone.now - 3.hours,
        hearing: create(:hearing, regional_office: "RO13")
      )
    end
    let!(:virtual_hearing_no_emails) do
      create(
        :virtual_hearing, :initialized,
        updated_at: Time.zone.now - 3.hours,
        hearing: create(:hearing, hearing_day: hearing_day, regional_office: "RO13")
      )
    end

    it "builds a report containing only virtual hearing where emails haven't sent" do
      subject.call

      report_lines = subject.report.split("\n")
      expect(report_lines).to include("Found 1 stuck virtual hearing: ")
      pending_line = report_lines[1]
      expect(pending_line).to include "VirtualHearing.find(#{virtual_hearing_no_emails.id})"
      expect(pending_line).to include "last attempted: never"
      display_scheduled_for = virtual_hearing_no_emails.hearing.scheduled_for.strftime("%a %m/%d")
      expect(pending_line).to include "scheduled for: #{display_scheduled_for}"
      expect(pending_line).to include "updated by: #{virtual_hearing_no_emails.updated_by.css_id}"
      expect(pending_line).to include "UUID: #{virtual_hearing_no_emails.hearing.uuid}"
    end
  end

  context "there are virtual hearings with pending conference and all emails haven't sent" do
    let!(:virtual_hearing) do
      create(
        :virtual_hearing, :initialized, :all_emails_sent,
        updated_at: Time.zone.now - 3.hours,
        hearing: create(:hearing, regional_office: "RO13")
      )
    end

    let!(:virtual_hearing_pending) do
      create(
        :virtual_hearing, :all_emails_sent,
        updated_at: Time.zone.now - 3.hours,
        hearing: create(:hearing, regional_office: "RO13")
      )
    end

    let!(:virtual_hearing_no_emails) do
      create(
        :virtual_hearing, :initialized,
        updated_at: Time.zone.now - 3.hours,
        hearing: create(:hearing, hearing_day: hearing_day, regional_office: "RO13")
      )
    end

    it "builds a report containing one where all emails haven't sent" do
      virtual_hearing_pending.establishment.attempted!

      subject.call

      report_lines = subject.report.split("\n")
      expect(report_lines).to include("Found 1 stuck virtual hearing: ")
      pending_line = report_lines[1]
      expect(pending_line).to include "VirtualHearing.find(#{virtual_hearing_no_emails.id})"
      expect(pending_line).to include "last attempted: never"
      display_scheduled_for = virtual_hearing_no_emails.hearing.scheduled_for.strftime("%a %m/%d")
      expect(pending_line).to include "scheduled for: #{display_scheduled_for}"
      expect(pending_line).to include "updated by: #{virtual_hearing_no_emails.updated_by.css_id}"
      expect(pending_line).to include "UUID: #{virtual_hearing_no_emails.hearing.uuid}"
    end
  end
end
