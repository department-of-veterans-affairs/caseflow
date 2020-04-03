# frozen_string_literal: true

describe VirtualHearings::SendEmail do
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
  let(:judge_recipient) do
    MailRecipient.new(name: "TEST", email: "america@example.com", title: :judge)
  end
  let(:veteran_recipient) do
    MailRecipient.new(name: "TEST", email: "america@example.com", title: :veteran)
  end
  let(:representative_recipient) do
    MailRecipient.new(name: "TEST", email: "america@example.com", title: :representative)
  end
  let(:send_email_job) do
    VirtualHearings::SendEmail.new(virtual_hearing: virtual_hearing, type: email_type)
  end

  describe ".call" do
    before do
      allow(send_email_job).to receive(:judge_recipient).and_return(judge_recipient)
      allow(send_email_job).to receive(:veteran_recipient).and_return(veteran_recipient)
      allow(send_email_job).to receive(:representative_recipient).and_return(representative_recipient)
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
          .with(mail_recipient: veteran_recipient, virtual_hearing: virtual_hearing)

        expect(VirtualHearingMailer)
          .to receive(:cancellation)
          .once
          .with(mail_recipient: representative_recipient, virtual_hearing: virtual_hearing)

        # NO for judge
        expect(VirtualHearingMailer)
          .to_not receive(:cancellation)
          .with(mail_recipient: judge_recipient, virtual_hearing: virtual_hearing)

        subject
      end
    end
  end
end
