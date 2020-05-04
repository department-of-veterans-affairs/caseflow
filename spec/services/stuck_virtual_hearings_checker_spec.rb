# frozen_string_literal: true

describe StuckVirtualHearingsChecker, :postgres do
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

    it "builds a report containing only pending virtual hearing" do
      subject.call

      report_lines = subject.report.split("\n")
      expect(report_lines).to include("Found 1 stuck virtual hearing: ")
      expect(report_lines).to include("VirtualHearing.find(#{virtual_hearing_pending.id}) last processed at ")
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
        hearing: create(:hearing, regional_office: "RO13")
      )
    end

    it "builds a report containing only virtual hearing where emails haven't sent" do
      subject.call

      report_lines = subject.report.split("\n")
      expect(report_lines).to include("Found 1 stuck virtual hearing: ")
      expect(report_lines).to include("VirtualHearing.find(#{virtual_hearing_no_emails.id}) last processed at ")
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
        hearing: create(:hearing, regional_office: "RO13")
      )
    end

    it "builds a report containing one virtual hearing with pending conference and one where all emails haven't sent" do
      virtual_hearing_pending.establishment.processed!

      subject.call

      report_lines = subject.report.split("\n")
      expect(report_lines).to include("Found 2 stuck virtual hearings: ")
      expect(report_lines).to include("VirtualHearing.find(#{virtual_hearing_pending.id}) " \
        "last processed at #{virtual_hearing_pending.establishment.processed_at}")
      expect(report_lines).to include("VirtualHearing.find(#{virtual_hearing_no_emails.id}) last processed at ")
    end
  end
end
