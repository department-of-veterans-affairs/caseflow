# frozen_string_literal: true

require "rails_helper"

RSpec.describe TranscriptFileIssuesMailer, type: :mailer do
  let(:subject_actions) do
    {
      download: "download",
      upload: "upload",
      convert: "conversion",
      retrieve: "retrieval"
    }
  end

  shared_examples "mail assignment" do
    it "assigns @details" do
      expect(mail.body.encoded).to match(details[:action])
      expect(mail.body.encoded).to match(details[:provider])
      expect(mail.body.encoded).to match(details[:docket_number]) if details[:docket_number]
    end
  end

  describe "#send_issue_details" do
    let(:details) do
      {
        action: "convert",
        provider: "rtf",
        docket_number: "12345"
      }
    end
    let(:appeal_id) { "12345678" }
    let(:mail) { described_class.send_issue_details(details, appeal_id).deliver_now }

    it "renders the subject" do
      subject_action = subject_actions[details[:action].to_sym].titlecase
      expect(mail.subject).to eq("File #{subject_action} Error - #{details[:provider]} #{details[:docket_number]}")
    end

    it "renders the receiver email" do
      expect(mail.to).to eq(["Caseflow@test.com"])
    end

    it "renders the sender email" do
      expect(mail.from).to eq(["BoardofVeteransAppealsHearings@messages.va.gov"])
    end

    include_examples "mail assignment"

    it "assigns @case_link" do
      expect(mail.body.encoded).to match("localhost:3000/queue/appeals/#{appeal_id}")
    end

    it "assigns @case_link for demo environment" do
      allow(Rails).to receive(:deploy_env).and_return(:demo)
      mail = described_class.send_issue_details(details, appeal_id).deliver_now
      expect(mail.body.encoded).to match("https://demo.appeals.va.gov/appeals/#{appeal_id}")
    end

    it "assigns @case_link for staging environment" do
      allow(Rails).to receive(:deploy_env).and_return(:uat)
      mail = described_class.send_issue_details(details, appeal_id).deliver_now
      expect(mail.body.encoded).to match("https://appeals.cf.uat.ds.va.gov/queue/appeals/#{appeal_id}")
    end

    it "assigns @case_link for prod environment" do
      allow(Rails).to receive(:deploy_env).and_return(:prod)
      mail = described_class.send_issue_details(details, appeal_id).deliver_now
      expect(mail.body.encoded).to match("https://appeals.cf.ds.va.gov/queue/appeals/#{appeal_id}")
    end
  end

  describe "#webex_recording_list_issues" do
    let(:details) do
      {
        action: "retrieve",
        provider: "Webex"
      }
    end
    let(:appeal_id) { "12345678" }
    let(:mail) { described_class.send_issue_details(details).deliver_now }

    it "renders the subject" do
      subject_action = subject_actions[details[:action].to_sym].titlecase
      expect(mail.subject).to eq("File #{subject_action} Error - #{details[:provider]}")
    end

    it "renders the receiver email" do
      expect(mail.to).to eq(["Caseflow@test.com"])
    end

    it "assigns to email address for prod environment" do
      allow(Rails).to receive(:deploy_env).and_return(:prod)
      expect(mail.to).to eq(["BVAHearingTeam@VA.gov"])
    end

    it "assigns cc email address for non prod environment" do
      expect(mail.cc).to eq(nil)
    end

    it "assigns cc email address for prod environment" do
      allow(Rails).to receive(:deploy_env).and_return(:prod)
      expect(mail.cc).to eq(["OITAppealsHelpDesk@va.gov"])
    end

    it "renders the sender email" do
      expect(mail.from).to eq(["BoardofVeteransAppealsHearings@messages.va.gov"])
    end

    include_examples "mail assignment"

    it "does not assign @case_link if times is present" do
      details[:times] = "10:00 AM"
      mail = described_class.send_issue_details(details).deliver_now
      expect(mail.body.encoded).not_to match("localhost:3000/queue/appeals/#{appeal_id}")
    end

    it "renders the correct message for FileConversionError" do
      details[:error] = TranscriptionTransformer::FileConversionError
      expected_message = "Please investigate this issue further to ensure " \
                          "Caseflow has been supplied with the necessary files"
      expect(mail.body.encoded).to match(expected_message)
    end

    it "renders the correct message for other errors" do
      details[:error] = "SomeOtherError"
      expected_message = "Please investigate this issue further to ensure continued " \
                      "communication between Caseflow and #{details[:provider]}."
      expect(mail.body.encoded).to match(expected_message)
    end
  end
end
