# frozen_string_literal: true

describe Hearings::HearingEmailStatusJob do
  describe "#perform" do
    subject { Hearings::HearingEmailStatusJob.new.perform }

    let!(:appellant_sent_hearing_email_event) do
      create(:sent_hearing_email_event, recipient_role: "appellant")
    end

    let!(:representative_sent_hearing_email_event) do
      create(:sent_hearing_email_event, recipient_role: "representative")
    end

    context "when GovDelivery throws an error" do
    end

    context "when reported status from GovDelivery is invalid" do
    end

    context "when reported status indicates success" do
      it "makes request to GovDelivery and handles status successfuly" do
        subject

        expect(appellant_sent_hearing_email_event.send_successful).to eq(true)
        expect(appellant_sent_hearing_email_event.send_successful_checked_at).not_to be_nil
        expect(representative_sent_hearing_email_event.send_successful).to eq(true)
        expect(representative_sent_hearing_email_event.send_successful_checked_at).not_to be_nil
      end
    end

    context "when reported status indicates failure" do
      it "makes request to GovDelivery and handles status successfuly" do
        subject

        expect(appellant_sent_hearing_email_event.send_successful).to eq(false)
        expect(appellant_sent_hearing_email_event.send_successful_checked_at).not_to be_nil
        expect(representative_sent_hearing_email_event.send_successful).to eq(false)
        expect(representative_sent_hearing_email_event.send_successful_checked_at).not_to be_nil
     end
    end
  end
end
