# frozen_string_literal: true

describe HearingEmailStatusMailer do
  describe "notification contents" do
    include Hearings::AppellantNameHelper
    include VirtualHearings::LinkHelper

    let(:original_recipient_email_address) { "test@caseflow.va.gov" }
    let(:hearing_coordinator_email_address) { "another-test@caseflow.va.gov" }
    let(:email_type) { "confirmation" }
    let(:hearing) { create(:hearing, :video) }
    let(:sent_by) { create(:user, email: hearing_coordinator_email_address) }
    let(:sent_hearing_email_event) do
      create(
        :sent_hearing_email_event,
        sent_by: sent_by,
        hearing: hearing,
        email_address: original_recipient_email_address,
        email_type: email_type
      )
    end
    let(:email) { described_class.notification(sent_hearing_email_event: sent_hearing_email_event) }

    it "has the correct subject" do
      hearing_type = Constants::HEARING_REQUEST_TYPES.key(hearing.request_type).titleize
      correct_subject = "#{hearing_type} #{email_type} email failed to send to #{original_recipient_email_address}"
      expect(email.subject).to eq(correct_subject)
    end

    it "has the formatted veteran name" do
      hearing_type = Constants::HEARING_REQUEST_TYPES.key(hearing.request_type).titleize
      veteran_formatted_name = formatted_appellant_name(hearing.appeal)
      veteran_sentence_fragment = "You scheduled a #{hearing_type} hearing for #{veteran_formatted_name}"

      expect(email.body).to include(veteran_sentence_fragment)
    end

    it "has the correct email address for the original_recipient" do
      email_sentence_fragment = "entered the #{sent_hearing_email_event.recipient_role} "\
                                "email #{original_recipient_email_address}"

      expect(email.body).to include(email_sentence_fragment)
    end

    it "has the correct link" do
      link = external_link hearing_details_url(hearing), display_text: "update it on the Hearing Details page"
      expect(email.body).to include(link)
    end
  end
end
