# frozen_string_literal: true

require "rails_helper"

RSpec.describe TranscriptionFileIssuesMailer, type: :mailer do
  let(:actions) do
    {
      download: "download",
      upload: "upload",
      conversion: "convert",
      retrieval: "retrieve"
    }
  end

  shared_examples "mail assignment" do
    it "assigns @details" do
      action = actions[details[:error][:type].to_sym]
      provider = details[:provider].titlecase
      expect(mail.body.encoded).to match(action)
      expect(mail.body.encoded).to match(provider)
      expect(mail.body.encoded).to match(details[:docket_number]) if details[:docket_number]
    end
  end

  describe "download transcription file job errors" do
    let(:appeal_id) { "12345678" }
    let(:details) do
      {
        error: { type: "download", explanation: "download a mp3 file from Webex" },
        provider: "webex",
        temporary_download_link: { link: "webex.com/download_link" },
        docket_number: "123456",
        appeal_id: appeal_id
      }
    end
    let(:mail) { described_class.issue_notification(details).deliver_now }

    it "renders the subject" do
      subject = "File #{details[:error][:type].titlecase} Error - " \
                + "#{details[:provider].titlecase} #{details[:docket_number]}"
      expect(mail.subject).to eq(subject)
    end

    it "renders the receiver email" do
      expect(mail.to).to eq(["Caseflow@test.com"])
    end

    it "renders the sender email" do
      expect(mail.from).to eq(["BoardofVeteransAppealsHearings@messages.va.gov"])
    end

    include_examples "mail assignment"

    it "assigns case details link" do
      expect(mail.body.encoded).to match("localhost:3000/queue/appeals/#{appeal_id}")
    end

    it "assigns case details link for demo environment" do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("DEPLOY_ENV").and_return("demo")
      mail = described_class.issue_notification(details).deliver_now
      expect(mail.body.encoded).to match("https://demo.appeals.va.gov/queue/appeals/#{appeal_id}")
    end

    it "assigns case details link for staging environment" do
      allow(Rails).to receive(:deploy_env).and_return(:uat)
      mail = described_class.issue_notification(details).deliver_now
      expect(mail.body.encoded).to match("https://appeals.cf.uat.ds.va.gov/queue/appeals/#{appeal_id}")
    end

    it "assigns case details link for prod environment" do
      allow(Rails).to receive(:deploy_env).and_return(:prod)
      mail = described_class.issue_notification(details).deliver_now
      expect(mail.body.encoded).to match("https://appeals.cf.ds.va.gov/queue/appeals/#{appeal_id}")
    end
  end

  describe "fetch webex recordings list errors" do
    let(:recording_id) { "12345" }
    let(:details) do
      {
        error: { type: "retrieval", explanation: "retrieve recording details from Webex" },
        provider: "webex",
        recording_id: recording_id,
        api_call: "GET webex.com/recordings/details//#{recording_id}",
        response: { status: 400, message: "Sample error message" }.to_json,
        docket_number: nil
      }
    end
    let(:mail) { described_class.issue_notification(details).deliver_now }

    it "renders the subject" do
      subject = "File #{details[:error][:type].titlecase} Error - #{details[:provider].titlecase}"
      expect(mail.subject).to eq(subject)
    end

    it "renders the receiver email" do
      expect(mail.to).to eq(["Caseflow@test.com"])
    end

    it "assigns to email address for prodtest environment" do
      allow(Rails).to receive(:deploy_env).and_return(:prodtest)
      expect(mail.to).to eq(["VHACHABID_Appeals_ProdTest@va.gov"])
    end

    it "assigns to email address for prodtest environment" do
      allow(Rails).to receive(:deploy_env).and_return(:uat)
      expect(mail.to).to eq(["BID_Appeals_UAT@bah.com"])
    end

    it "assigns to email address for prod environment" do
      allow(Rails).to receive(:deploy_env).and_return(:prod)
      expect(mail.to).to eq(["BVAHearingTeam@VA.gov"])
    end

    it "assigns cc email address for prod environment" do
      allow(Rails).to receive(:deploy_env).and_return(:prod)
      expect(mail.cc).to eq(["OITAppealsHelpDesk@va.gov"])
    end

    it "assigns cc email address for non prod environment" do
      expect(mail.cc).to eq(nil)
    end

    it "renders the sender email" do
      expect(mail.from).to eq(["BoardofVeteransAppealsHearings@messages.va.gov"])
    end

    include_examples "mail assignment"

    it "renders the correct message for FileConversionError" do
      details.delete(:provider)
      expected_message = "Please investigate this issue further to ensure " \
                          "Caseflow has been supplied with the necessary files"
      expect(mail.body.encoded).to match(expected_message)
    end

    it "renders the correct message for other errors" do
      expected_message = "Please investigate this issue further to ensure continued " \
                      "communication between Caseflow and #{details[:provider].titlecase}."
      expect(mail.body.encoded).to match(expected_message)
    end
  end
end
