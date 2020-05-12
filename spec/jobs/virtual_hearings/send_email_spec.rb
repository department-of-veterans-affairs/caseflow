# frozen_string_literal: true

describe VirtualHearings::SendEmail do
  let(:nyc_ro_eastern) { "RO06" }
  let(:judge_email_sent) { false }
  let(:representative_email_sent) { false }

  let!(:virtual_hearing) do
    create(
      :virtual_hearing,
      hearing: hearing,
      judge_email_sent: judge_email_sent,
      representative_email_sent: representative_email_sent,
      appellant_email_sent: appellant_email_sent
    )
  end
  let(:email_type) { nil }
  let(:judge_recipient) do
    MailRecipient.new(
      name: "TEST",
      email: "america@example.com",
      title: MailRecipient::RECIPIENT_TITLES[:judge]
    )
  end
  let(:appellant_recipient) do
    MailRecipient.new(
      name: "TEST",
      email: "america@example.com",
      title: MailRecipient::RECIPIENT_TITLES[:appellant]
    )
  end
  let(:representative_recipient) do
    MailRecipient.new(
      name: "TEST",
      email: "america@example.com",
      title: MailRecipient::RECIPIENT_TITLES[:representative]
    )
  end
  let(:send_email_job) do
    VirtualHearings::SendEmail.new(virtual_hearing: virtual_hearing, type: email_type)
  end

  describe ".call" do
    subject do
      send_email_job.call
    end

    before do
      allow(send_email_job).to receive(:judge_recipient).and_return(judge_recipient)

      allow(send_email_job).to receive(:representative_recipient).and_return(representative_recipient)
    end

    context "veteran name is populated" do
      before do
        allow(send_email_job).to receive(:veteran_recipient).and_return(veteran_recipient)
      end

      context "a cancellation email" do
        let(:email_type) { :cancellation }



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

    context "veteran name is not populated" do
      let(:veteran) do
        create(
          :veteran,
          first_name: nil,
          last_name: nil,
          file_number: "12345678"
        )
      end

      it "fetches veteran from BGS" do
        expect(virtual_hearing.hearing.appeal.veteran)
          .to receive(:update_cached_attributes!)
          .once
          .and_call_original

        subject
      end
    end
  end
end
