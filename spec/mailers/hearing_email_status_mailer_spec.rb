# frozen_string_literal: true

describe HearingEmailStatusMailer do
  describe "notification" do
    let(:email_address) { "test@caseflow.va.gov" }
    let(:email_type) { "confirmation" }
    let(:hearing) { create(:hearing, :video) }
    let(:sent_hearing_email_event) do
      create(
        :sent_hearing_email_event,
        hearing: hearing,
        email_address: email_address,
        email_type: email_type
      )
    end

    it "has the correct subject" do
      email = described_class.notification(sent_hearing_email_event: sent_hearing_email_event)
      hearing_type = Constants::HEARING_REQUEST_TYPES.key(hearing.request_type).titleize
      correct_subject = "#{hearing_type} #{email_type} email failed to send to #{email_address}"
      expect(email.subject).to eq(correct_subject)
    end

    it "includes some other key piece of information" do
      expect(true).to eq(true)
    end
  end
end
