# frozen_string_literal: true

describe VirtualHearings::SendEmail, :all_dbs do
  let(:nyc_ro_eastern) { "RO06" }
  let(:judge_email_sent) { false }
  let(:representative_email_sent) { false }
  let(:veteran_email_sent) { false }
  let(:hearing) { create(:hearing, regional_office: nyc_ro_eastern) }
  let!(:virtual_hearing) do
    create(
      :virtual_hearing,
      hearing: hearing,
      judge_email_sent: judge_email_sent,
      representative_email_sent: representative_email_sent,
      veteran_email_sent: veteran_email_sent
    )
  end
  let(:email_type) { nil }
  let(:mail_recipients) do
    {
      veteran: instance_double(MailRecipient),
      judge: instance_double(MailRecipient),
      representative: instance_double(MailRecipient)
    }
  end
  let(:send_email_job) { VirtualHearings::SendEmail.new(virtual_hearing: virtual_hearing, type: email_type) }
  let(:virtual_hearing_mailer) { double(VirtualHearingMailer) }

  describe ".call" do
    before do
      allow(VirtualHearings::SendEmail).to receive(:new).and_return(send_email_job)
      allow(send_email_job).to receive(:mail_recipients).and_return(mail_recipients)
      allow(virtual_hearing_mailer).to receive(:deliver_now)
    end

    subject do
      send_email_job.call
    end

    context "a cancellation email" do
      let(:email_type) { :cancellation }

      it "calls VirtualHearingMailer.cancellation for everyone but the judge", :aggregate_failures do
        # YES for veteran and representative
        expect(VirtualHearingMailer)
          .to receive(:cancellation)
          .once
          .with(mail_recipient: mail_recipients[:veteran], virtual_hearing: virtual_hearing)
          .and_return(virtual_hearing_mailer)

        expect(VirtualHearingMailer)
          .to receive(:cancellation)
          .once
          .with(mail_recipient: mail_recipients[:representative], virtual_hearing: virtual_hearing)
          .and_return(virtual_hearing_mailer)

        # NO for judge
        expect(VirtualHearingMailer)
          .to_not receive(:cancellation)
          .with(mail_recipient: mail_recipients[:judge], virtual_hearing: virtual_hearing)

        subject
      end
    end
  end
end
