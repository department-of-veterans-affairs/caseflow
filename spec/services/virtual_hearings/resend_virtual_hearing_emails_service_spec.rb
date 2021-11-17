# frozen_string_literal: true

describe VirtualHearings::ResendVirtualHearingEmailsService do
  let(:sample_bad_email) {
    "This is a bad email it contains care.va.gov which is the bad url"
  }
  let(:start_date) { '2021-01-01' }
  let(:end_date) { '2021-01-10' }
  subject { VirtualHearings::ResendVirtualHearingEmailsService.call(start_date: start_date, end_date: end_date) }
  before do
    allow(VirtualHearings::ResendVirtualHearingEmailsService)
      .to receive(:get_gov_delivery_message_body)
      .and_return({body: sample_bad_email})
    @se = create(
      :sent_hearing_email_event,
      sent_at: Time.zone.parse('2021-01-02'),
      email_type: "confirmation"
    )
    @hearing_email_recipient = create(
      :hearing_email_recipient,
      hearing: @se.hearing,
      email_sent: false,
      type: "AppellantHearingEmailRecipient"
    )
    @virtual_hearing = create(
      :virtual_hearing,
      hearing: @se.hearing
    )
    @se.hearing.hearing_day.update(scheduled_for: 2.days.from_now)
  end

  describe ".call" do 
    it "resends emails for confirmation email" do
      subject
      expect(@hearing_email_recipient.reload.email_sent).to eq(true)
    end
    it "doesnt resend emails if a reminder email has been sent" do
      @se.update(email_type: "reminder")
      subject
      expect(@hearing_email_recipient.reload.email_sent).to eq(false)
    end
    it "doesnt resend emails if hearing already occured" do
      @se.hearing.hearing_day.update(scheduled_for: Time.zone.now - 2.days)
      subject
      expect(@hearing_email_recipient.reload.email_sent).to eq(false)
    end
  end
  describe ".custom_email_subject" do
    it "returns correct email subject" do
      expect(VirtualHearings::ResendVirtualHearingEmailsService.custom_email_subject(@se.hearing)).to eq(
        "Updated confirmation (please disregard previous email): Bob Smithdouglas's Board hearing is #{@se.hearing.scheduled_for.to_formatted_s(:short_date)} -- Do Not Reply"
      )
    end
  end
  describe ".is_bad_email?" do
    it "returns true if contains care.va.gov" do
      expect(VirtualHearings::ResendVirtualHearingEmailsService.is_bad_email?(sample_bad_email)).to eq(true)
    end
    it "returns false if does not contain care.va.gov" do
      expect(VirtualHearings::ResendVirtualHearingEmailsService.is_bad_email?("test email")).to eq(false)
    end
  end
end