# frozen_string_literal: true

describe VirtualHearings::ResendVirtualHearingEmailsService do
  let(:sample_bad_email) do
    "This is a bad email it contains care.va.gov which is the bad url"
  end
  let(:start_date) { "2021-01-01" }
  let(:end_date) { "2021-01-10" }
  subject do
    VirtualHearings::ResendVirtualHearingEmailsService.call(
      start_date: start_date, end_date: end_date, perform_resend: true
    )
  end
  before do
    allow(VirtualHearings::ResendVirtualHearingEmailsService)
      .to receive(:get_gov_delivery_message_body)
      .and_return(body: sample_bad_email)
    @se = create(
      :sent_hearing_email_event,
      # All tests should also work with this comented out, which creates an AMA hearing
      # :legacy,
      sent_at: Time.zone.parse("2021-01-02"),
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
      initial_sent_email_event_count = @se.hearing.email_events.count
      subject
      expect(@hearing_email_recipient.reload.email_sent).to eq(true)
      expect(@se.hearing.email_events.count).to eq(initial_sent_email_event_count + @se.hearing.email_recipients
        .where(hearing_type: @se.hearing.class.name).count)
    end
    it "doesnt resend emails if a reminder email has been sent" do
      @se.update(email_type: "reminder")
      subject
      expect(@hearing_email_recipient.reload.email_sent).to eq(false)
    end
    it "doesnt resend emails if hearing already occured" do
      # Works for AMA Hearings
      @se.hearing.hearing_day.update(scheduled_for: Time.zone.now - 2.days)
      # Fake legacy hearings are complex, so just mock the scheduled_for return
      allow_any_instance_of(LegacyHearing)
        .to receive(:scheduled_for)
        .and_return(Time.zone.now - 2.days)
      subject
      expect(@hearing_email_recipient.reload.email_sent).to eq(false)
    end
    it "doesnt resend emails outside of the expected date range" do
      @se.update(sent_at: "2022-01-01")
      subject
      expect(@hearing_email_recipient.reload.email_sent).to eq(false)
    end
    it "doesnt resend emails twice" do
      subject
      expect(@hearing_email_recipient.reload.email_sent).to eq(true)
      @hearing_email_recipient.update(email_sent: false)
      subject
      expect(@hearing_email_recipient.reload.email_sent).to eq(false)
      expect(@se.reload.sent_by).to eq(User.system_user)
    end
  end
  describe "Continues without failing when RecipientIsDeceasedVeteran errors encountered" do
    before do
      allow_any_instance_of(Hearings::SendEmail)
        .to receive(:send_email)
        .and_raise(Hearings::SendEmail::RecipientIsDeceasedVeteran)
    end
    it "continues" do
      expect(Raven).to receive(:capture_exception)
        .with(Hearings::SendEmail::RecipientIsDeceasedVeteran, any_args)
      subject
    end
  end
  describe "Continues without failing when VacolsRecordNotFound errors encountered" do
    before do
      allow(HearingRepository)
        .to receive(:load_vacols_data)
        .and_raise(Caseflow::Error::VacolsRecordNotFound)
    end

    it "continues" do
      # This only applies to VACOLS (Legacy) Hearings
      if @se.hearing.class.name == "LegacyHearing"
        expect(Raven).to receive(:capture_exception)
          .with(Caseflow::Error::VacolsRecordNotFound, any_args)
        subject
      end
    end
  end
  describe ".custom_email_subject" do
    it "returns correct email subject" do
      expect(VirtualHearings::ResendVirtualHearingEmailsService.custom_email_subject(@se.hearing)).to eq(
        "Updated confirmation (please disregard previous email): " \
        "#{@se.hearing.appeal.appellant_or_veteran_name}'s Board hearing is " \
        "#{@se.hearing.scheduled_for.to_formatted_s(:short_date)} -- Do Not Reply"
      )
    end
  end
  describe ".bad_email?" do
    it "returns true if contains care.va.gov" do
      expect(VirtualHearings::ResendVirtualHearingEmailsService.bad_email?(sample_bad_email)).to eq(true)
    end
    it "returns false if does not contain care.va.gov" do
      expect(VirtualHearings::ResendVirtualHearingEmailsService.bad_email?("test email")).to eq(false)
    end
  end
end
